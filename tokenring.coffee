law(tokenring,language(coffeescript))

# Variable to store the IP address of the host
host = "172.31.16.185"

# Special agents in the system
manager = "manager@" + host
server = "server@" + host

###
Law for the agents
###

###
Section 1. Rules that govern the additon of a new member to the ring
###
# When an agent joins the system, he sends a "join" message to the manager
UPON "adopted", ->
    # If a new agent wants to join to the ring, once he adopts the law a "join" message is sent to the coordinator
    if @self isnt manager and @self isnt server
        DO "forward", sender: @self, receiver: manager, message:
            action: "join",
            member: @self
        # Sets a status to store the previous and next member of the ring
        # The default values are the same actor
        DO "set", key: "previous", value: @self
        DO "set", key: "next", value: @self
        return true
    
# When an agent receives the instruction "insert" from the manager, he sends an accepted message to the new member
# with the value of his next property. After that, he updates his own next property to the name of the new member
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.action is "insert"
        DO "forward", sender: @self, receiver: @message.member, message:
            action: "accepted",
            next: CS("next") 
        DO "set", key: "next", value: @message.member
        DO "deliver"
        DO "deliver", sender: @self, receiver: @self, message:
            previous: CS("previous")
            next: CS("next")
        return true 
    
# When a new member is accepted, he updates his own previous and next properties to the values sent by the agent
# that accepted him into the ring
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.action is "accepted"
        DO "set", key: "previous", value: @sender
        DO "set", key: "next", value: @message.next
        # We send a message to the next member so he can update his previous property
        DO "forward", sender: @self, receiver: @message.next, message:
            action: "update",
            member: @self
        DO "deliver"
        DO "deliver", sender: @self, receiver: @self, message:
            previous: CS("previous")
            next: CS("next")
        return true
    
# When an agent receives the instruction "update" from the new member, he updates his previous property with the name of the new member
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.action is "update"
        DO "set", key: "previous", value: @message.member
        DO "deliver"
        DO "deliver", sender: @self, receiver: @self, message:
            previous: CS("previous")
            next: CS("next")
        return true
    
# When an agent disconnects from the system, he sends a "leave" message to the previous member of the ring
UPON "disconnected", ->
    if @self isnt manager and @self isnt server and CS("previous") isnt @self
        DO "forward", sender: @self, receiver: CS("previous"), message:
            action: "leave"
            next: CS("next")
        DO "quit"
        return true
    
# When an agent receives the instruction "leave" from another agent, he updates his next property and send
# a message "remove" to the manager so he can update the list of member of the ring
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.action is "leave"
        DO "set", key: "next", value: @message.next
        DO "forward", sender: @self, receiver: manager, message:
            action: "remove",
            member: @sender
        DO "forward", sender: @self, receiver: @message.next, message:
            action: "update",
            member: @self
        DO "deliver", sender: @self, receiver: @self, message:
            previous: CS("previous")
            next: CS("next")
        return true

###
UPON "arrived", ->  
    DO "deliver"
    return true
###

###
Law for the manager
###
UPON "adopted", ->
    # this part of the law only applies when the manager joins to the system
    if @self is manager
        DO "set", key: "members", value: []
        DO "set", key: "token_assigned", value: "no"
        return true

UPON "sent", ->
    DO "forward"
    return true
        
UPON "arrived", ->
    # When someone joins the ring
    if @self is manager and @message.action is "join"
        # Displays a message showing what is happening
        DO "deliver", sender: @sender, receiver: @receiver, message: @message.member + " wants to " + @message.action
        # Adds the new actor to the list of members
        members = CS("members")
        # If the list of members is not empty, we send an "insert" message to the last member of the ring
        if members.length > 0
            DO "forward", sender: @self, receiver: members[members.length - 1], message:
                action: "insert",
                member: @message.member
        members.push @message.member
        DO "deliver", sender: @sender, receiver: @receiver, message: members
        DO "set", key: "members", value: members
        return true
    
UPON "arrived", ->
    # When someone has left the ring, the manager removes his name from the member list
    if @self is manager and @message.action is "remove"
        # Removes the actor from the list of members
        members = CS("members")
        pos = members.indexOf(@message.member)
        members.splice(pos,1)
        DO "deliver", sender: @sender, receiver: @receiver, message: members
        DO "set", key: "members", value: members
        return true