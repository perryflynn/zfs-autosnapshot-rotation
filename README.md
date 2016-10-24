# zfs-autosnapshot-rotation

Create and rotate zfs snapshots automatically.

```
root@eisenbart# ./zfsautosnap.sh myraidz/files autosnap 3
[1/6] Delete myraidz/files@autosnap-20161024-164226
[2/6] Delete myraidz/files@autosnap-20161024-172345
[3/6] Delete myraidz/files@autosnap-20161024-191540
[4/6] Delete myraidz/files@autosnap-20161024-192536
[5/6] Delete myraidz/files@autosnap-20161024-192538
[6/6] Delete myraidz/files@autosnap-20161024-192637
Create new snapshot myraidz/files@autosnap-20161024-222403
Done
```

- Create snapshots via cron job
- Delete automatically old snapshots

## Parameters

- ZFS volume name
- Snapshot prefix
- Number of concurrent snapshots

