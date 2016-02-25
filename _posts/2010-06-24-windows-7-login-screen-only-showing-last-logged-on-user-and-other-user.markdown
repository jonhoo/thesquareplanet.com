---
layout: post
title: Windows 7 login screen only showing last logged-on user and "Other user"
date: '2010-06-24 06:23:38'
---

Ever since my initial install of Windows 7, there has been one thing nagging me. The Windows welcome screen only ever displayed the avatar for the last logged on user and a blank image with the label "Other users". When the latter was clicked, two text fields would appear prompting for username and password.

I have tried [numerous solutions](http://social.answers.microsoft.com/Forums/en-US/w7security/thread/63cea659-f6a0-412d-a0b1-952a26c1df44), but none have worked until very recently when a user with the nickname "SaySay" came up with the following [solution](http://social.answers.microsoft.com/Forums/en-US/w7security/thread/63cea659-f6a0-412d-a0b1-952a26c1df44#9c76b69e-02e2-4f9f-9c09-19edd0f9dea5):

><span style="color:#800000;">**Legal disclaimer**: Modifying REGISTRY settings incorrectly can cause serious problems that may prevent your computer from booting properly. Neither I nor Microsoft can guarantee that any problems resulting from the configuring of REGISTRY settings can be solved. Modifications of these settings are at your own risk</span>

 1. Open regedit
    1. Press Windows+R
    2. Type regedit + enter
 2. Navigate to `[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList]`
 3. You will probably want to right-click on `ProfileList` and click export to save the entire subtree in case something goes wrong.
 4. You will find several subfolders or "keys" named something like `S-1-x-xx...`, open them one at the time
 5. Each should contain at least the three value-sets, `Flags`, `ProfileImagePath` and `State`, some will contain more
    1. Look at the end of `ProfileImagePath` for the name of the user represented by the key
    2. You will usually have one for each user on the system, and one for each of the three system entries `systemprofile`, `LocalService` and `NetworkService`
 6. Delete any key (i.e. the whole `S-1-x-xx` folder) that does not contain at least those three values
 7. The welcome screen should now work as expected, showing the avatar for all registered users; enjoy!

**UPDATE 2011-08-05**: I've been made aware that the `.DEFAULT` directory should also be deleted if present (if it is a subdirectory of `ProfileList` that is...). Thanks to [Shawn Melton](http://meltondba.wordpress.com/2011/02/08/welcome-to-windows-7/).