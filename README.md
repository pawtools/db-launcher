# db-launcher

Currently this works through the LSF job manager.

Job gets launched, database should come up, nothing happens during a 100 second
sleep, and job shuts down. The database wrappers should write a host IP, which
disappears when the job terminates.
