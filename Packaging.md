# Packaging options for common libraries

At Figure, we are deploying N applications using tensorflow and other shared libraries in common. We are exploring three packaging options, 
(1) a debian package for each application and each shared library 
(2) a single docker image containing all the applications and the shared libraries 
(3) or a docker image for each application containing the shared libraries used by the application.


a. What would be your process to select the right solution?
b. What are the pros/cons of each approach?
c. Should we use static or dynamic libraries?
