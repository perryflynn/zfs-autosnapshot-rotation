# [EXPERIMENTAL] zfs-autosnapshot-rotation

Create and rotate zfs snapshots automatically.

- Create snapshots via cron job
- Delete automatically old snapshots
- Snapshot creation only when filesystem changed since last snapshot

## Parameters

- ZFS volume name
- Snapshot prefix
- Number of concurrent snapshots

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
