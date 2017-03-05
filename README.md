# [EXPERIMENTAL] zfs-autosnapshot-rotation

Create and rotate zfs snapshots automatically.

- Create snapshots via cron job
- Delete automatically old snapshots
- Snapshot creation only when filesystem changed since last snapshot

## Parameters

```
ZFS-Auto-Snapshot-Rotation

Target tank does not exist!

zfsautosnap.sh: Take and rotate snapshots on a ZFS file system

  Usage:
  zfsautosnap.sh [options]

  -t, --target   Required, name of ZFS file system to act on
  -n, --name     Required, base name for snapshots,
                 followed by the current timestamp
  -c, --count    Required, number of snapshots in snap_name.timestamp
                 format to keep at one time.
  --clearall     Delete all snapshots created by zfsautosnap.sh for given target
  -h, --help     Print this help
```

## FAQ

- **New snapshot was created but i haven't changed anything!**
  
  In most cases this is the access time (atime) of ZFS. See the property `atime` and disable it.
  `zfs set atime=off myraifz/files` and `zfs inherit myraidz/files/foo; zfs inherit myraidz/files/bar`

## Example output

```
root@eisenbart:/media/files/admin/zfstools# ./zfsautosnap.sh myraidz/files asnapdaily 3

ZFS-Auto-Snapshot-Rotation

[20161025 12:53:33] Begin on "myraidz/files" for "asnapdaily"
[20161025 12:53:33] 2 snapshots found
[20161025 12:53:33] 0 old snapshots detected
[20161025 12:53:33] The newest "asnapdaily" snapshot in "myraidz/files" is "asnapdaily-20161025-125144"
[20161025 12:53:34] Changes since last snapshot detected
Create new snapshot "myraidz/files@asnapdaily-20161025-125333"
[20161025 12:53:34] Done

root@eisenbart:/media/files/admin/zfstools# ./zfsautosnap.sh myraidz/files asnapdaily 3

ZFS-Auto-Snapshot-Rotation

[20161025 12:53:41] Begin on "myraidz/files" for "asnapdaily"
[20161025 12:53:41] 3 snapshots found
[20161025 12:53:41] 1 old snapshots detected
[20161025 12:53:41] The newest "asnapdaily" snapshot in "myraidz/files" is "asnapdaily-20161025-125333"
[20161025 12:53:42] No changes since last snapshot. Abort.
[20161025 12:53:42] Done
```
