law(tokenring,language(coffeescript))

# Variable to store the IP address of the host
host = "172.31.21.201"

# Max time allowed to have the token (in seconds)
max_time = 7
# Waiting time for the manager before regenerating the token
regeneration_time = 10

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
            type: "join",
            member: @self
        # Sets a status to store the previous and next member of the ring
        # The default values are the same actor
        DO "set", key: "previous", value: @self
        DO "set", key: "next", value: @self
        # Sets a status to store if this agent has the token
        DO "set", key: "has_token", value: "no"
        return true
    
# When an agent receives the instruction "insert" from the manager, he sends an accepted message to the new member
# with the value of his next property. After that, he updates his own next property to the name of the new member
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.type is "insert"
        DO "forward", sender: @self, receiver: @message.member, message:
            type: "accepted",
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
    if @self isnt manager and @self isnt server and @message.type is "accepted"
        DO "set", key: "previous", value: @sender
        DO "set", key: "next", value: @message.next
        # We send a message to the next member so he can update his previous property
        DO "forward", sender: @self, receiver: @message.next, message:
            type: "update",
            member: @self
        DO "deliver"
        DO "deliver", sender: @self, receiver: @self, message:
            previous: CS("previous")
            next: CS("next")
        return true
    
# When an agent receives the instruction "update" from the new member, he updates his previous property with the name of the new member
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.type is "update"
        DO "set", key: "previous", value: @message.member
        DO "deliver"
        DO "deliver", sender: @self, receiver: @self, message:
            previous: CS("previous")
            next: CS("next")
        return true
    
# When an agent disconnects from the system, he sends a "leave" message to the previous member of the ring
UPON "disconnected", ->
    if @self isnt manager and @self isnt server and CS("previous") isnt @self
        # Notifies the previous agent that someone is about to leave
        DO "forward", sender: @self, receiver: CS("previous"), message:
            type: "leave"
            next: CS("next")
        # If this agent has the token, he passes the token to the next agent
        DO "forward", sender: @self, receiver: CS("next"), message:
            type: "token"
        # Leaves the system gracefully
        DO "quit"
        return true
    
# When an agent receives the token, he updates his property 'has_token' to the value 'yes'
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.type is "token"
        DO "set", key: "has_token", value: "yes"
        DO "forward", sender: @self, receiver: manager, message:
            type: "token received",
            actor: @self
        DO "deliver", sender: @sender, receiver: @receiver, message: "I have the token"
        # Imposes the obligation to pass the token every second
        DO "impose_obligation", type: "max_time", time: max_time
        return true

# When the obligation expires, forces passing the token
UPON "obligation_due", ->
    if @type is "max_time"
        DO "forward", sender: @self, receiver: @self, message:
            type: "pass",
            repeal: "no"
        return true
    
# When an agent receives the order to pass the token
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.type is "pass" and CS("has_token") is "yes"
        DO "set", key: "has_token", value: "no"
        DO "forward", sender: @self, receiver: CS("next"), message:
            type: "token"
        DO "deliver"
        return true
    
# When an agent receives the instruction "leave" from another agent, he updates his next property and send
# a message "remove" to the manager so he can update the list of member of the ring
UPON "arrived", ->
    if @self isnt manager and @self isnt server and @message.type is "leave"
        DO "set", key: "next", value: @message.next
        DO "forward", sender: @self, receiver: manager, message:
            type: "remove",
            member: @sender
        DO "forward", sender: @self, receiver: @message.next, message:
            type: "update",
            member: @self
        DO "deliver", sender: @self, receiver: @self, message:
            previous: CS("previous")
            next: CS("next")
        return true
    
# When an agent tries to send a message to the server, verify that he has the token
UPON "sent", ->
    if @receiver is server
        if CS("has_token") is "yes"
            DO "forward"
        return true

###
Law for the manager
###

# When the manager joins to the system, creates an empty array to store the list of members
UPON "adopted", ->
    # this part of the law only applies when the manager joins to the system
    if @self is manager
        DO "set", key: "members", value: []
        return true

# When a new agent joins the ring, the manager sends an "insert" message to the last member
# of the ring and adds the new members to the list of members (array)
UPON "arrived", ->
    # When someone joins the ring
    if @self is manager and @message.type is "join"
        # Displays a message showing what is happening
        DO "deliver", sender: @sender, receiver: @receiver, message: 
            action: @message.type
            member: @message.member
        # Adds the new actor to the list of members
        members = CS("members")
        # If this is the first member, we pass him the token
        if members.length == 0
            DO "forward", sender: @self, receiver: @message.member, message:
                type: "token"
        # If the list of members is not empty, we send an "insert" message to the last member of the ring
        if members.length > 0
            DO "forward", sender: @self, receiver: members[members.length - 1], message:
                type: "insert",
                member: @message.member
        members.push @message.member
        DO "deliver", sender: @sender, receiver: @receiver, message: 
            type: "member list"
            content: members
        DO "set", key: "members", value: members
        return true
    
UPON "arrived", ->
    # When someone has left the ring, the manager removes his name from the member list
    if @self is manager and @message.type is "remove"
        # Removes the actor from the list of members
        members = CS("members")
        pos = members.indexOf(@message.member)
        members.splice(pos,1)
        DO "deliver", sender: @sender, receiver: @receiver, message: 
            action: @message.type
            member: @message.member
        DO "deliver", sender: @sender, receiver: @receiver, message: 
            type: "member list"
            content: members
        DO "set", key: "members", value: members
        return true
    
UPON "arrived", ->
    # When someone passes the token, imposes an obligation to create the token again
    if @self is manager and @message.type is "token received"
        DO "repeal_obligation", type: "regenerate_token"
        DO "impose_obligation", type: "regenerate_token", time: regeneration_time
        DO "deliver"
        return true

UPON "obligation_due", ->
    if @type is "regenerate_token"
        members = CS("members")
        DO "deliver", sender: @self, receiver: @self, message:
            type: "token regenerated",
            member: members[0]
        DO "forward", sender: @self, receiver: members[0], message:
                type: "token"
        return true
    
###
Rules for the server
###
UPON "arrived", ->
    if @self is server
        DO "deliver", sender: @sender, receiver: @receiver, message: @message + " (" + @sender + ")"
        return true
    
###
Default rules (apply only if none of the previous conditions was fulfilled)
###

UPON "arrived", ->  
    DO "deliver"
    return true

UPON "sent", ->
    DO "forward"
    return true