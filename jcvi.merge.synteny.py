#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import argparse

def argsParser():
	parser = argparse.ArgumentParser(prog=sys.argv[0], add_help=True, formatter_class=argparse.RawDescriptionHelpFormatter, description = f"""
Usage: %(prog)s -1 in1.genesyn -2 in2.gensyn -3 in3.genesyn -c out.genesyn [options]

Requirements:
    argparse

Descriptions:
    merge 3 gene synteny into one file
    missing data filled by NaN

Format:
    in1.genesyn [3-col]: A01\tB01\t[INT]
    in2.genesyn [3-col]: B01\tD01\t[INT]
    in3.genesyn [3-col]: A01\tD01\t[INT]
    out.genesyn: A01\tB01\t[BLOCK]\tB01\tD01\t[BLOCK]\tA01\tD01\t[BLOCK]\t[===/###]
""", epilog="""

Example:
  %(prog)s -1 AA.BB.anchors.new.uniq -2 BB.DD.anchors.new.uniq -3 AA.DD.anchors.new.uniq -o AABBDD.synteny

################# AUTHORS #########################
#  Fu-Hao Lu
#  FRSB, Dr.
#  State Key Lorboratory of Crop Stress Adaptation and Improvement
#  Jinming Campus, Henan University
#  Kaifeng 475004, Henan Province, China
#  E-mail: lufuhao@henu.edu.cn
""")
	parser.add_argument('-1', action='store', required = True, dest='syn1', type=str, metavar='<file>', help='Input synteny file 1')
	parser.add_argument('-2', action='store', required = True, dest='syn2', type=str, metavar='<file>', help='Input synteny file 2')
	parser.add_argument('-3', action='store', required = True, dest='syn3', type=str, metavar='<file>', help='Input synteny file 3')
	parser.add_argument('-c', "--score", action='store', default=0, required = False, dest="score", type=int, metavar='<INT>', help='Minimum cutoff score in col3, default: %(default)s')
	parser.add_argument('-m', "--missing", action='store_true', default=False, required = False, dest="miss", help='Whether to print missing syntenies, default: %(default)s')
	parser.add_argument('-r', "--problematic", action='store_true', default=False, required = False, dest="prob", help='Whether to print problematic syntenies, default: %(default)s')
	parser.add_argument('-o', "--output", action='store', default="MyOut.synteny.tab", required = False, dest="output", type=str, metavar='<FILE>', help='Output file, default: %(default)s')
	args = parser.parse_args()
	return args



def readSyntenyData(synfile,RSDscore):
	RSDdict1={}
	RSDdict2={}
	RSDnumblock=0
	RSDnumline=0
	RSDvadline=0
	RSDobj=open(synfile, "r")
	for RSDline in RSDobj:
		RSDnumline+=1
		RSDline=RSDline.strip()
		if RSDline.startswith("###"):
			RSDnumblock+=1
			continue
		RSDlist=RSDline.split("\t")
		if len(RSDlist) <3:
			sys.stderr.write ("Error: invalid line ("+str(RSDnumline)+"): "+RSDline+"in file "+synfile+"\n")
			sys.exit(100)
		if int(RSDlist[2])<RSDscore:
			continue
		if RSDlist[0] in RSDdict1:
			sys.stderr.write ("Error: duplicated ID1 at line ("+str(RSDnumline)+"): "+RSDlist[0]+"in file "+synfile+"\n")
			sys.exit(100)
		if RSDlist[1] in RSDdict2:
			sys.stderr.write ("Error: duplicated ID2 at line ("+str(RSDnumline)+"): "+RSDlist[1]+"in file "+synfile+"\n")
			sys.exit(100)
		RSDdict2[RSDlist[1]]=1
		RSDdict1[RSDlist[0]]={}
		RSDdict1[RSDlist[0]]['a']=RSDlist[1]
		RSDdict1[RSDlist[0]]['b']=str(RSDnumblock)
		RSDvadline+=1
	RSDobj.close()
	RSDdict2={}
	print ("### file: ")
	print ("    Total Lines : "+str(RSDnumline))
	print ("    Total Blocks: "+str(RSDnumblock))
	print ("    Valid Lines : "+str(RSDvadline))
	print ("    Keys in dict: "+str(len(RSDdict1.keys())))
	return RSDdict1

def mergeDict(dict1,dict2,dict3, MDout, MDmiss,MDprob):
	MDnumout_all=0
	MDnumout_good=0
	MDnumout_good_prob=0
	MDnumout_missing2=0
	MDnumout_missing3=0
	MDnumout_missing23=0
	MDobj=open(MDout, "w")
	for MDkey1 in dict1:
		MDnumout_all+=1
		MDkey2=dict1[MDkey1]['a']
		MDlist=[]
		if MDmiss:
			MDlist.append(MDkey1)
			MDlist.append(MDkey2)
			MDlist.append(dict1[MDkey1]['b'])
		if MDkey1 in dict2 and MDkey2 in dict3:
			if MDmiss:
				MDlist=MDlist+[MDkey1, dict2[MDkey1]['a'],dict2[MDkey1]['b']]
				MDlist=MDlist+[MDkey2, dict3[MDkey2]['a'],dict3[MDkey2]['b']]
			else:
				MDlist=MDlist+[MDkey1, MDkey2, dict3[MDkey2]['a']]
			if dict3[MDkey2]['a'] == dict2[MDkey1]['a']:
				MDlist.append("+++")
				MDnumout_good+=1
			else:
				MDlist.append("***")
				MDnumout_good_prob+=1
				if MDprob:
					MDlist.append(dict2[MDkey1]['a'])
				else :
					continue
		elif MDkey1 in dict3 and MDkey2 in dict2:
			if MDmiss:
				MDlist=MDlist+[MDkey2, dict2[MDkey2]['a'],dict2[MDkey2]['b']]
				MDlist=MDlist+[MDkey1, dict3[MDkey1]['a'],dict3[MDkey1]['b']]
			else:
				MDlist=MDlist+[MDkey1, MDkey2, dict2[MDkey2]['a']]
			if dict2[MDkey2]['a'] == dict3[MDkey1]['a']:
				MDlist.append("+++")
				MDnumout_good+=1
			else:
				MDlist.append("***")
				MDnumout_good_prob+=1
				if MDprob:
					MDlist.append(dict3[MDkey1]['a'])
				else:
					continue
		elif MDkey1 in dict2:
			MDnumout_missing3+=1
			if MDmiss:
				MDlist=MDlist+[MDkey1, dict2[MDkey1]['a'],dict2[MDkey1]['b']]
				MDlist=MDlist+['NaN', 'NaN', 'NaN']
				MDlist.append("***")
			else:
				continue
		elif MDkey1 in dict3:
			MDnumout_missing2+=1
			if MDmiss:
				MDlist=MDlist+['NaN', 'NaN', 'NaN']
				MDlist=MDlist+[MDkey1, dict3[MDkey1]['a'],dict3[MDkey1]['b']]
				MDlist.append("***")
			else:
				continue
		elif MDkey2 in dict2:
			MDnumout_missing3+=1
			if MDmiss:
				MDlist=MDlist+[MDkey2, dict2[MDkey2]['a'],dict2[MDkey2]['b']]
				MDlist=MDlist+['NaN', 'NaN', 'NaN']
				MDlist.append("***")
			else:
				continue
		elif MDkey2 in dict3:
			MDnumout_missing2+=1
			if MDmiss:
				MDlist=MDlist+['NaN', 'NaN', 'NaN']
				MDlist=MDlist+[MDkey2, dict3[MDkey2]['a'],dict3[MDkey2]['b']]
				MDlist.append("***")
			else:
				continue
		else:
			MDnumout_missing23+=1
			if MDmiss:
				MDlist=MDlist+['NaN', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN']
				MDlist.append("***")
			else:
				continue
		MDobj.write("\t".join(MDlist)+"\n")
	MDobj.close()
	print ("\n\n### OUT summary ###")
	print ("  All           : "+str(MDnumout_all))
	print ("    1  2  3     : "+str(MDnumout_good))
	print ("    1  *  3     : "+str(MDnumout_missing2))
	print ("    1  2  *     : "+str(MDnumout_missing3))
	print ("    1  *  *     : "+str(MDnumout_missing23))
	print ("    problematic : "+str(MDnumout_good_prob))
	return 0



if __name__ == '__main__':
	arg=argsParser()
	dic1=readSyntenyData(arg.syn1, arg.score)
	dic2=readSyntenyData(arg.syn2, arg.score)
	dic3=readSyntenyData(arg.syn3, arg.score)
	mergeDict(dic1, dic2, dic3, arg.output, arg.miss, arg.prob)
	print ("\n\n\n### DONE ###")
