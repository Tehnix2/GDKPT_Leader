# GDKPT_Leader

This is raid leader version of GDKPT. You only need to have the raid leader version if you want to host a GDKP using GDKPT yourself. I recommend disabling the raid leader addon when participating in a GDKP that you are not hosting.

The Raid Leader is the only source of truth for all raid members, and GDKPT_RaidLeader handles all of the addon message sending back & forth.

# Additional Features

- You can customize auction parameters like auction duration, extra time per bid, starting bid for all items and minimum increment in gold.
- Version Check functionality: Make all raid members post their current GDKPT version in raid chat.
- Auction Start functionality: Simply mouseover an item in your inventory and press the mouseover Auction Start Macro (Default Bag Frames and Bagnon from Ascension launcher are supported currently)
- Automatic Masterlooting to yourself: Press the macro or click the Announce & Auto-Loot button to automatically all green, blue, epic, legendary or artifact items to yourself.
  This will instantly add the looted items to every raid members Loot Tracker, and helps them keep track of trade timers for BoP items.
- Balance - Tracker panel: Always see the gold raid members either still need to pay or still need to receive
- Auction & Auction Setting re-synchronization available through a button click, if this is ever needed
- Auction Data Export into CSV, Plain Text, 2 Screenshots with customizeable rows or JSON
- Raid Snapshot System: Save Auction data as snapshots. These can be loaded & unloaded at any time
- Bulk Toggle List: Press a macro to add items to a bulk list, then start an auction on your Hearthstone to create a Bulk Auction
- Pot-Split functionality: Press a button to split the total gold equally among all raid members
- Auction Reset for all raid members available through a button click
- TradeHelper frame that automatically shows the items a player won. If it was BoE, the TradeHelper will automatically place that BoE item into the trade slots. If it was BoP, you need to click that item on the TradeHelper frame.
- Tooltip Expansion that helps with keeping track of already auctioned items and who won them (or if they went to the Bulk)
- All Data is saved through reloads, logouts and server crashes
- There are now some additional features available to recover data from raid members if the raidleader has a client crash and loses data



# Useage Guide

1. Right-Click the GDKPT Leader Toggle Button in order to bring up the Leader Frame.
2. Click 'Reset All Auctions' so you start fresh (if needed)
3. Assign Auction Parameters for your raid: Auction Duration, Extra Time per Bid, Starting Bid, Minimum Increment. Experiment with what feels good for you and your raid.
4. Type /gdkp macro to bring up the Macro Generator.
5. Copy paste the following Macros out of the Macro Generator, create the macros and keybind them
   5.1 RaidLeader: Start Auction Macro or Bagnon Start Auction Macro (depending on which one you are using)
   5.2 RaidLeader: Auto MasterLoot Macro
   5.3 RaidLeader: Bulk Item Toggle
6. Left-Click the GDKPT Leader Toggle Button in order to bring up the Balance Window
7. Open the GDKPT Auction Window (either full mode or compact mode) and Synchronize up if needed
8. Mouseover the item you want to auction off, and press the auction start macro. Repeat for all items you want to auction at the same time. 
9. VERY IMPORTANT: DO NOT MOVE THE ITEM IN YOUR BAGS ANYMORE AFTER YOU STARTED AN AUCTION ON THEM, OTHERWISE TRADE HELPER WILL NOT BE ABLE TO CORRECTLY ASSIGN THE ITEM
10. Players will now bid on items and after the auction duration ended the winners will trade you. The Trade Helper frame will open up to the right of the Trade Frame and show you the items the player has won. If it was a BoE item, Trade Helper auto places the item into the Trade Window. If it was a BoP item, you need to click the item on the Trade Helper frame. No Drag & Dropping is required.
11. Repeat the Auctioning & Loot Trading / Gold Collecting until all items are handled or you want to split the pot (keep BoP item trade timers in mind!)
12. Everything that noone has bid on is going into a Bulk. Use the Bulk Toggle Macro on all items you want to add to the Bulk List. Look at item tooltips to keep track.
13. Once all Bulk - Items are added to the bulk list, use the Auction Start Macro on your Hearthstone. This triggers a Bulk Auction for everyone that lists all items that went into the Bulk. The bulk list can handle atleast up to 50 items, probably even more.
14. Give the Bulk - Auction - Winner all their items (Trade Helper is still abit messy with this part), probably some Drag & Dropping required.
15. Once all items are handed out and you collected all the gold, its time to split the pot. Press the 'Ready for Pot Split Button' underneath the Balance Tracker.
16. This will check for offline players in the raid. Decide if you want to keep those (in case they contributed alot and only went offline recently) or remove those players. The next step will divide the total gold pot by the amount of players in your raid (online + offline, if there is anyone offline).
17. Click Yes on the confirmation prompt if you want to split the pot.
18. Click the Split Pot Now Button on the Balance Tracker if you want to split the pot now. This adds (total pot / current raid player count) to everyones balance (balances will be green).
19. Players will trade you for their Cut now. Click the Cut: X Gold button on the upper part of the Trade Frame.
20. Repeat until everyone got their gold (except you as leader, since you cannot trade yourself)
21. Click Raid Snapshots and then Save Snapshot if you want to save the data
22. Click Export Raid Data and choose your prefered Export Format in order to export data.

Thats it, you are now a GDKP Organizer. Welcome to the club!



<img width="851" height="857" alt="grafik" src="https://github.com/user-attachments/assets/94ecb1ad-1071-4b4d-a372-765ce6b65b2b" />

<img width="659" height="592" alt="grafik" src="https://github.com/user-attachments/assets/f5fa6873-1496-4968-a3f3-61b4ca2858aa" />

<img width="893" height="919" alt="grafik" src="https://github.com/user-attachments/assets/f3b264cf-ba58-47c3-81e9-11d244f09f27" />

<img width="862" height="656" alt="grafik" src="https://github.com/user-attachments/assets/8b9136e0-cd82-4455-a7f3-72faae187511" />

<img width="846" height="645" alt="grafik" src="https://github.com/user-attachments/assets/b5803f31-f816-4492-92a8-6c03840c7296" />

<img width="318" height="470" alt="grafik" src="https://github.com/user-attachments/assets/dc725922-aa6e-4e15-bdb3-f5490c179f97" />

<img width="813" height="662" alt="grafik" src="https://github.com/user-attachments/assets/f08b6b43-5815-4b32-8604-c08c39f4acbf" />

<img width="791" height="931" alt="grafik" src="https://github.com/user-attachments/assets/0955a3a9-34de-4018-9d9f-6e57de33a699" />












