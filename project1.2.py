import subprocess
import networkx as nx
import matplotlib.pyplot as plt
import time
from colorama import init
init()                          # Initialize the colors

def main():

    # This visualization requires you to manually start the controller
    # This visualization requires you to manually start the server

    visual = subprocess_reader('C:/Moses/Moses/manager.bat') # Executing the manager

def subprocess_reader(file):

    actors = ['foo','bar','baz','qux']   # Actors list to compare with the command line

    G=nx.Graph()                          # Generating "networkx" graph
    
    p = subprocess.Popen(file, stdout=subprocess.PIPE)
    # Grab stdout line by line as it becomes available.   
    # This will loop until p terminates.
    
    while p.poll() is None:
        l = p.stdout.readline()             # This blocks until it receives a newline.
        print('\033[31m'+"\n",l,"\n")       # Prints the current line in manager
        m = str(l)                          # Stores the current line

        if m.find('join') != -1:            # If the line contains the word 'join' does...
            print('\033[33m'+"---> A member has been added")  # Prints Yellow 
            for a in actors:                # Compares the current line with the list of actors
                if m.find(a) != -1:         # If finds and actor
                    G.add_node(a)               # Adds the actor who was found,
                                                # Does not creates duplicates
                    mx = G.number_of_nodes()        # Storages the number of nodes
                    print(mx)
                    if mx == 1:                     # If the number of nodes is 1 
                        first = a                   # The current node is the first
                    elif mx == 2:                   # If there are 2 nodes
                        G.add_edge(first,a)         # Creates a link between first and 
                    elif mx == 3:                   # If there are 3 nodes
                        G.add_edge(last,a)      # Creates a link between the last and the current
                        G.add_edge(a,first)     # * Creates a link between the current and the first
                    elif mx == 4:                   # If there are 4 nodes
                        G.remove_edge(last,first)   # Removes the link between the last and first *
                        G.add_edge(last,a)          # Creates a link between the previous and the current
                        G.add_edge(a,first)         # Creates a link between the current and the first

                last = a                # saving current node for following edge
                    
                nx.draw_circular(G)         # Draw the link
                    
        elif m.find('member list') != -1:   # If command line is and update of the member list
            members = int(m.count('@'))     # Counts the '@' and returns it as the number of nodes
            if members == 0:                # If there are no members left
                G.clear()                   # Clears the graph

            nx.draw_circular(G)         # Redraws the graph
                                   
            print('\033[34m'+"---> Agents in the token ring: ",G.nodes()) # Prints Blue
            
        elif m.find('token received') != -1:    # If the line is about token received does...       
            for act in actors:                  # for actor in list of actors
                if m.find(act) != -1:           # If one is found that's who got the token
                    token = act                     # Storages the actor who got the token            
                    nx.draw_circular(G)         # Redraws the graph
                                        
                    print('\033[32m'+"---> ",token," has the token!")   # Prints Blue
                    
        elif m.find('remove') != -1:
            print('\033[36m'+"---> A member abandoned the ring")  # Prints cyan
            for a1 in actors:
                if m.find(a1) != -1:
                    G.remove_node(a1)
                    nodes1 = G.nodes()
                    G.add_edge(nodes1[-1],nodes1[0])
                    nx.draw_circular(G)
        plt.show()
        
    # When the subprocess terminates there might be unconsumed output
    # that still needs to be processed.
    print (p.stdout.read())
    deinit()


main()
