import subprocess

def main():
    #subprocess_reader('C:/Moses/Moses/start_controller.bat')
    #subprocess_reader('C:/Moses/Moses/test.bat')

    open1 = input('This visualization requires you to manually start the controller \n when is done press "Y": ')
    
    open2 = input('This visualization requires you to manually start the server \n when is done press "Y": ')
    
    if (open1 == 'Y') and (open2 == 'Y'):
        visual = subprocess_reader('C:/Moses/Moses/manager.bat')
    else:
        print('Please open the files and try again')

def subprocess_reader(file):

    actors = ['foo','bar','baz','qux']
    
    p = subprocess.Popen(file, stdout=subprocess.PIPE)
    # Grab stdout line by line as it becomes available.  This will loop until 
    # p terminates.
    while p.poll() is None:
        l = p.stdout.readline() # This blocks until it receives a newline.
        print ("\n",l,"\n")
        m = str(l)
        if m.find('join') != -1:
            print("---> A member has been added")
        elif m.find('member list') != -1:
            members = int(m.count('@'))
            temp_actors = []
            #print("Number of agents in the token ring = ",members)
            for ac in actors:
                if m.find(ac) != -1:
                    temp_actors.append(ac)
            print("---> Agents in the token ring: ",temp_actors)
        elif m.find('token received') != -1:
            for act in actors:
                if m.find(act) != -1:
                    token = act
                    print("---> ",token," has the token!")
        elif m.find('remove') != -1:
            print("---> A member abandoned the ring")
         
    # When the subprocess terminates there might be unconsumed output
    # that still needs to be processed.
    print (p.stdout.read())


main()
