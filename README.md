This repository exists to simply host a very small portion of some bash scripts I have developed over time for various needs / projects. 

The fasta checker file is a small script that is used to take a fasta file as input either single or multi, and validate the proper formatting of the file, in that is contains appropriate headers and characters within their respective locations

the emboss automation script is a developemental script that is a smaller part of a larger docker pipeline. It contains the core functionality of what is built into the docker container and to be executed at image call. It performs a number
of functions from the EMBOSS suite including ORF (open reading frame) finding, reverse complement and reverse translation of sequences.
