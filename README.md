# db-launcher

Usage:

```bash
./runme.sh
```

Currently this works through the LSF job manager on ORNL Summit. To use it, you
will have to change:
 - mongo.bashrc PATH prepends to match the location of this repo copy
 - mongo.bashrc PATH prepends point to your mongodb bin folder

Job gets launched, database should come up, nothing happens during a 100 second
sleep, and job shuts down. The database wrappers should write a host IP, which
disappears when the job terminates.

TODO
 - does launch_amongod.sh need the separate 'launch' methods?
   - the difference just looks like the timestamp on L41
