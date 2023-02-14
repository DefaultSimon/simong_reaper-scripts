<h1 align="center">
    Simon Goričar's <a href="https://www.reaper.fm/">Reaper</a> Scripts
</h1>

## 1. Installation
You can use this repository via [ReaPack](https://reapack.com) by adding the following 
repository:
```
https://github.com/DefaultSimon/simong_reaper-scripts/raw/master/index.xml
```

## 2. Contents

### 2.1. `Monitoring FX Bypass scripts (based on FX names containing "[BYPASSABLE]")`

This package contains the following three actions:
- `Bypass all monitoring FX whose names contain "[BYPASSABLE]"`
- `Toggle bypass on all monitoring FX whose names containin "[BYPASSABLE]"`
- `Unbypass all monitoring FX whose names contain "[BYPASSABLE]"`

These actions operate on the monitoring FX chain *only*, and only bypass/unbypass FX
that contain `[BYPASSABLE]` somewhere in their name. To rename a monitoring FX, open the monitoring FX chain, then `Right Click -> Rename FX instance` to rename your FX).

<details>
<summary>*SWS Cycle Action preset* for this package</summary>

Because these scripts are handier with a toggleable SWS cycle action (requires [SWS](https://sws-extension.org/index.php)), I've included 
a preconfigured cycle action in the `Cycle Action/simong_CycleAction_Toggle (bypass and unbypass) monitoring FX whose name contains the phrase [BYPASSABLE].ini` preset file.

Simply [download the file](https://github.com/DefaultSimon/simong_reaper-scripts/blob/master/Cycle%20Actions/simong_CycleAction_Toggle%20(bypass%20and%20unbypass)%20monitoring%20FX%20whose%20name%20contains%20the%20phrase%20%5BBYPASSABLE%5D.ini),
then go to `Extensions -> Cycle Action editor... -> Import/export -> Import in section 'Main'...`, select the file, then click `Apply`.

</details>

---

### 2.2. `Move selected media items onto child track whose name contains "[STEMS]"`

This script moves the selected media items from the track they are on to the child "stem collection" track. It finds that track by looking at the track's direct children and finding a track whose name
contains the phrase "[STEMS]".

If no "[STEMS]"-matching track is found or if no media items are selected, this script does nothing.

#### Why
This is part of a personal workflow thing I'm testing: 
- I record a loop,
- I use this action to push the recorded material into a child track that sends to the parent 
  (so I can still hear what I just recorded), 
- then I can record a new "overdub" on the original track I just emptied 
  (but it's just a new item I'm recording, not a real overdub).

This makes it easier to separate multiple overdub "chunks" of your material into separate items 
and name them accordingly.

#### Quirks
- Due to how items are moved, if not all of the selected media items are on the same track, the script *might* work, but will pick a "stem collector" child from the first selected media item.

---

### 2.3. `Create new empty MIDI track at the same position as the selected media item`

This script creates a new empty MIDI track at the same position (and of the same length) as the currently-selected media item. It also unselects the original media item and selects the newly created one.

---

## 3. Developing
I try to adhere to the [semantic versioning rules](https://semver.org/#semantic-versioning-200) if at all possible.
