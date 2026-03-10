# User Guide: How to use Site Blocker

Follow these instructions to ensure your sites are blocked correctly and immediately.

## 1. How to Block a Site
1. Open the app and tap **Add Site**.
2. Enter the domain name (e.g., `example.com`).
3. Tap **Save**. The site is now in your blocklist.

## 2. Important: Making it "Instant"
When you add a new site, it is saved in the app immediately, but your **browser** might still remember the site's address (this is called "DNS Caching").

### If a site is still loading after you block it:
1. **Pull-to-Refresh:** In the Site Blocker app, pull down on the home screen to refresh. This forces the VPN to update its internal rules.
2. **Kill your Browser:**
   - Swipe up from the bottom of your phone to see all open apps.
   - **Swipe away your Browser** (Chrome, Firefox, etc.) to close it completely.
   - This clears the browser's memory of the "unblocked" site.
3. **Re-open the Browser:** Now visit the site again, and it will be blocked.

## 3. Why is this necessary?
Phones and browsers try to be fast by "remembering" where sites are. If you visited a site *before* blocking it, your phone might not ask the VPN for the address again for a few minutes. Closing the browser forces it to ask the VPN, which then says "this site does not exist."

## 4. Private DNS Warning
If you see a warning about "Private DNS," you must:
1. Go to **Android Settings**.
2. Search for **Private DNS**.
3. Set it to **Off**.
4. Return to the app.
*Note: Site blocking cannot work if Private DNS is enabled because it bypasses the VPN tunnel.*
