# Privacy review

This repository was prepared for public release with a minimal privacy surface.

## Removed or avoided

The repository does not include:

- Windows user profile paths such as `C:\Users\...`;
- local Desktop paths;
- personal folder names;
- screenshots;
- exported CSV diagnostic files;
- serial numbers;
- GitHub account-specific paths inside scripts.

## Included

The repository includes generic examples such as:

```text
Primary
\\.\DISPLAY2\Monitor0
```

`\\.\DISPLAY2\Monitor0` is a Windows display identifier example, not a personal filesystem path. Users should replace it with their own monitor string if needed.

## Notes

The scripts default to `Primary` to avoid embedding a specific machine configuration. The PowerShell script also resolves `ControlMyMonitor.exe` relative to the script location instead of hard-coding an absolute local path.
