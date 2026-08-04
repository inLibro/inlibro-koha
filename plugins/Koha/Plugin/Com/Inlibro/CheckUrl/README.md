# Koha Plugin – CheckUrl

## Description

The **CheckUrl** plugin for the **Koha** ILS allows running the internal script  
**`check-url-quick.pl`** directly from the Koha interface.  
It simplifies link verification (especially those in field **856u**) within bibliographic records.

---

## Features

* Execution of the **`check-url-quick.pl`** script from Koha.
* Home page with a **“Check URL”** button.
* Results page displaying a report of URLs and return codes.

---

## Installation

1. Copy the **CheckUrl** plugin directory into the Koha plugins folder:

   ```bash
   /var/lib/koha/<instance>/plugins/
    ```

2. Restart **Plack** or **Apache** if necessary.

3. Log in to the Koha intranet.

4. Enable the plugin via the menu:
   **Administration > Koha Plugins > CheckUrl plugin > Action: Enable**

**Prerequisite**: the script `check-url-quick.pl` must be present in `misc/cronjobs/`.

---

## Usage

1. Log in to the Koha intranet.
2. Run the plugin via the menu:
   **Administration > Koha Plugins > CheckUrl plugin > Action: Run**
3. The plugin home page will be displayed with a **“Check URL”** button.
4. Click the button to start the analysis.
5. The results will appear in a table.

---

## Example Results

```
Check URL Results

83    /ftp://ftp.umontreal.ca/               599 Only http and https URL schemes supported
247   https://en.wikipedia.org/wiki/Z123456  404 Not Found
345   /irc.oftc.net:6667                     599 Only http and https URL schemes supported
556   /file://home/marieluce/Downloads/...   599 Only http and https URL schemes supported
686   http://www.gutenberg.org/ebooks/1691   404 Not Found
2688  http://www.gutenberg.org/ebooks/23651  599 Only http and https URL schemes supported
```

* The first column corresponds to the **record number**.
* The second column is the URL being tested.
* The third column is the return code or error message.

---

## Maintenance

* **Uninstallation**: possible from the interface (no persistent data).
* **Updates**: uninstall the old version before installing the new one.

---

## Metadata

* **Name**: CheckUrl
* **Authors**: Alexandre Noel, Noah Tremblay
* **Description**: Runs `check-url-quick.pl` and displays the results in Koha
* **Version**: 2.0
* **Creation date**: August 15, 2024
* **Last updated**: September 8, 2025

---

