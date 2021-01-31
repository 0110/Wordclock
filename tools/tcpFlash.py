#!/usr/bin/python

import argparse
import socket
import os.path
import sys      #for exit and flushing of stdout
import time

def sendRecv(s, message, answer):
    msg = message + "\n"
    s.sendall(msg)
    reply = s.recv(4096)
    i=1
    while ((not (answer in reply)) and (i < 10)):
        reply += s.recv(4096)
        i = i + 1
    if answer not in reply:
        return False
    else:
        return True

def sendCmd(s, message, cleaningEnter=False):
    msg = message + "\n"
    s.sendall(msg)
    time.sleep(0.050)
    reply = s.recv(4096)
    i=1
    while ((not (">" in reply)) and (i < 10)):
        time.sleep((0.050) * i)
        reply += s.recv(4096)
        i = i + 1

#    print "Send\t" + message
#    print "Got\t" + reply
    if (cleaningEnter):
        s.sendall("\n")
    if "stdin:1:" in reply:
       print "ERROR, received : " + reply
       return False
    elif ">" in reply:
        return True
    else:
        print "ERROR, received : " + reply
        return False

def main(nodeip, luafile, volatile=None):
    if ( not os.path.isfile(luafile) ):
        print "The file " + luafile + " is not available"
    else:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((nodeip, 23))
	    time.sleep(0.050)
            s.sendall("\n")
            # Receive the hello Message of answer of the ESP
            if (not sendRecv(s, "\n", "Welcome to ") ):
                print "Cannot connect to the ESP"
                s.close()
                sys.exit(2)
            
            # Read all lines from the welcome message
            i=0
            reply = s.recv(4096)
            while ((reply is not None) and (not (">" in reply)) and (i < 100)):
                reply = s.recv(4096)
                i = i + 1


            # Communication tests
            if ( not sendRecv(s, "print(12345)", "12345") ):
                print "NOT communicating with an ESP8266 running LUA (nodemcu) firmware"
                s.close()
                sys.exit(3)
    
            sendCmd(s, "for i=0,5 do tmr.stop(i) end")
            sendCmd(s, "collectgarbage()")
            if (volatile is None):
                print "Flashing " + luafile
                sendCmd(s, "file.remove(\"" + luafile+"\");", True)
                sendCmd(s, "w= file.writeline", True)
                sendCmd(s, "file.open(\"" + luafile + "\",\"w+\");", True)
            else:
                print "Executing " + luafile + " on nodemcu"

            with open(luafile) as f:
                contents = f.readlines()
                i=1
                for line in contents:
                    print "\rSending " + str(i) + "/" + str(len(contents)) + " ...",
                    sys.stdout.flush()
                    l = line.rstrip()
		    if ( l.endswith("]") ):
			l = l + " "
			print "add a space at the end"

                    if (volatile is None):
                        if (not sendCmd(s, "w([==[" + l + "]==]);")):
                            print "Cannot write line " + str(i)
                            s.close()
                            sys.exit(4)
                    else:
                        if (not sendCmd(s, l)):
                            print "Cannot write line " + str(i)
                            s.close()
                            sys.exit(4)
                    i=i+1

            if (volatile is None):
                # Finished with updating the file in LUA
                if (not sendCmd(s, "w([[" + "--EOF" + "]]);")):
                    print "Cannot write line " + "-- EOF"
                if (not sendCmd(s, "file.close();")):
                    print "Cannot close the file"
                    sys.exit(4)
                
                # Check if the file exists:
                if (not sendRecv(s, "=file.exists(\"" + luafile + "\")", "true")):
                    print("Cannot send " + luafile + " to the ESP")
                    sys.exit(4)
                else:
                    print("Updated " + luafile + " successfully")
            else:
                print("Send " + luafile + " successfully")

            # Cleaning the socket by closing it
            s.close()
            sys.exit(0) # Report that the flashing was succesfull
        except socket.error, msg:
            print 'Failed to create socket. Error code: ' + str(msg[0]) + ' , Error message : ' + msg[1]
            sys.exit(1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--target', help='IP address or dns of the ESP to flash')
    parser.add_argument('-f', '--file', help='LUA file, that should be updated')
    parser.add_argument('-v', '--volatile', help='File is executed at the commandline', action='store_const', const=1)

    args = parser.parse_args()

    if (args.target and args.file and args.volatile):
        main(args.target, args.file, args.volatile)
    elif (args.target and args.file):
        main(args.target, args.file)
    else:
        parser.print_help()
