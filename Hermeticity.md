# Hermeticity
A build is hermetic if it is not affected by the details of the environment where it is performed. 

## How would you verify that the build is hermetic?

Here are the different approaches to fish for hermeticity issues :  
1) Diff the execution logs between minor changes to the environment. 
2) Use Bazel's "WorkspaceEvents" log to look for rules that reach and grab details from the host system. https://docs.bazel.build/versions/master/workspace-log.html
3) Code review for common patterns of known hermetic issues. For example, in C++ projects, the linkOpts may refer to sharedLibs from the host systems.
4) Getting external dependencies via bzlMod or ensuring they are pinned to a certain SHA-id is a good way to verify external library dependencies. (show example fo hermetic python, and other with pinned SHA-ID)

## Is there any hermeticity issue or limitation with this project?

1) non-hermetic clang usage
2) shared library reference in 3rd party libs. 





