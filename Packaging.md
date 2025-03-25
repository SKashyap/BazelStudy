# Packaging options for common libraries

At Figure, we are deploying N applications using TensorFlow and other shared libraries in common. We are exploring three packaging options, 
(1) a Debian package for each application and each shared library 
(2) a single docker image containing all the applications and the shared libraries 
(3) or a docker image for each application containing the shared libraries used by the application.


# What would be your process to select the right solution?

I would ideally ask these questions first:
- Understand what is the deployment architecture of these N applications. Target deployment platform matters to our decision. 
- Understand how each of the N applications consumes the shared library in question.
- Do we have a set of libraries identified as a "Shared kernel" for all applications developed in this organization?
- Understand the dependency between the N applications and the shared kernel.
- Do all libraries within this "Shared kernel" have a similar frequency of updates? We typically don't want to group a frequenty changing library with a rare one and call it a shared kernel.
- what is the size of this kernel?


## A Debian/RPM package for each application and each shared library : 

b. What are the pros/cons of each approach?
c. Should we use static or dynamic libraries?
