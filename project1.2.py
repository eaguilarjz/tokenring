import subprocess
import networkx as nx
import matplotlib.pyplot as plt
import time
from colorama import init
init()

def main():
    #subprocess_reader('C:/Moses/Moses/start_controller.bat')
    #subprocess_reader('C:/Moses/Moses/test.bat')

    #open1 = input('This visualization requires you to manually start the controller \n when is done press "Y": ')
    
    #open2 = input('This visualization requires you to manually start the server \n when is done press "Y": ')
    
    #if ((open1 and open2 == 'Y') or (open1 and open2 == 'y')):
    visual = subprocess_reader('C:/Moses/Moses/manager.bat')
    #else:
    #print('Please open the files and try again')

def subprocess_reader(file):

    actors = ['foo','bar','baz','qux']

    G=nx.Graph()
    
    p = subprocess.Popen(file, stdout=subprocess.PIPE)
    # Grab stdout line by line as it becomes available.  This will loop until 
    # p terminates.
    while p.poll() is None:
        l = p.stdout.readline() # This blocks until it receives a newline.
        print('\033[31m'+"\n",l,"\n")
        m = str(l)
        if m.find('join') != -1:
            print('\033[33m'+"---> A member has been added")
            for a in actors:
                if m.find(a) != -1:
                    
                    G.add_node(a)
                    
                    mx = G.number_of_nodes()

                    if mx == 1:
                        first = a
                    elif mx == 2:
                        G.add_edge(first,a)
                    elif mx == 3:
                        G.add_edge(last,a)
                        G.add_edge(a,first)
                    elif mx == 4:
                        G.remove_edge(last,first)
                        G.add_edge(last,a)
                        G.add_edge(a,first)

                    last = a    # saving current node for following edge
                    
                    nx.draw_circular(G)
                    
        elif m.find('member list') != -1:
            members = int(m.count('@'))
            if members == 0:
                
                G.clear()
                nx.draw_circular(G)
                
            #temp_actors = []
            #print("Number of agents in the token ring = ",members)
            '''for ac in actors:
                if m.find(ac) != -1:
                  
                    temp_actors.append(ac)'''
                    
            print('\033[34m'+"---> Agents in the token ring: ",G.nodes())
        elif m.find('token received') != -1:
            for act in actors:
                if m.find(act) != -1:
                    token = act

                    G.node[token]['Token']='YES'
                    G.node[token]['color']='blue'

                    nx.draw_circular(G)
                                        
                    print('\033[32m'+"---> ",token," has the token!")
        elif m.find('remove') != -1:
            print('\033[36m'+"---> A member abandoned the ring")
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
