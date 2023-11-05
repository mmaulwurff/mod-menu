// SPDX-FileCopyrightText: 2022-2023 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

version 4.11

/// Entry point 1. Builds Mod Menu when an options menu is opened before Mod Menu.
class OptionMenuItemmm_Injector : OptionMenuItem
{

  void init() {}

  override void onMenuCreated()
  {
    mm_Builder.build();
  }

} // class OptionMenuItemmm_Injector

/// Entry point 2. Builds Mod Menu when Mod Menu is opened before an options menu.
class mm_Menu : OptionMenu
{

  override void init(Menu parent, OptionMenuDescriptor descriptor)
  {
    Super.init(parent, descriptor);

    mm_Builder.build();
  }

} // class mm_Menu

/// Builds Mod Menu: collects modded menus and cleans up base option menus.
class mm_Builder : OptionMenuItem
{
  const FULL_OPTIONS_MENU   = "OptionsMenu";
  const SIMPLE_OPTIONS_MENU = "OptionsMenuSimple";
  const MOD_MENU            = "mm_Options";

  static void build()
  {
    let modMenuDescriptor = getDescriptor(MOD_MENU);

    if (modMenuDescriptor.mItems.size() != 0) return;

    let itemInfo = new("mm_ItemInfo").init();

    fill(itemInfo, modMenuDescriptor.mItems);

    bool hasModMenus = (modMenuDescriptor.mItems.size() != 0);

    modifyMenu(FULL_OPTIONS_MENU,   hasModMenus, itemInfo);
    modifyMenu(SIMPLE_OPTIONS_MENU, hasModMenus, itemInfo);
  }

  /// Builds the contents of Mod Menu by collecting items from the full options
  /// menu, simple options menu, and from controls menu, and makes sure that
  /// there are no duplicates.
  private static void fill(mm_ItemInfo itemInfo, out array<OptionMenuItem> target)
  {
    fillModMenuFrom(FULL_OPTIONS_MENU,   itemInfo, target);
    fillModMenuFrom(SIMPLE_OPTIONS_MENU, itemInfo, target);
    addMenusFromKeys (target);
    addNotListedMenus(target);
    addMenuFromMain  (target);

    removeDuplicates(target);
  }

  /// Replaces mod menus with Mod Menu.
  private static void modifyMenu(string menuName, bool hasModMenus, mm_ItemInfo itemInfo)
  {
    let optionsDescriptor = getDescriptor(menuName);
    if (!hasModMenus)
    {
      // Remove the last item. There is no other mods, so it must be the injector.
      optionsDescriptor.mItems.pop();
      return;
    }

    // Remove everything mod-related.
    Array<OptionMenuItem> baseItems;
    bool isPreviousLineBlank = false;
    foreach (item : optionsDescriptor.mItems)
    {
      if (item is "OptionMenuItemmm_Injector") continue;

      // This is sometimes added to the menu by GZDoom code.
      if (item.mLabel == "---------------") continue;

      // Consecutive blank lines.
      if (item is "OptionMenuItemStaticText" && item.mLabel.length() <= 1)
      {
        if (isPreviousLineBlank) continue;
        else isPreviousLineBlank = true;
      }
      else
      {
        isPreviousLineBlank = false;
      }

      if (!itemInfo.isModded(item)) baseItems.push(item);
    }
    optionsDescriptor.mItems.move(baseItems);

    // Add Mod Menu.
    optionsDescriptor.mItems.push(new("OptionMenuItemSubmenu").init("$MM_OPTIONS", MOD_MENU));
  }

  /// Returns option menu descriptor by the menu name.
  private static OptionMenuDescriptor getDescriptor(Name aName)
  {
    return OptionMenuDescriptor(MenuDescriptor.getDescriptor(aName));
  }

  /// Copies non-standard menu items from a menu to target.
  private static void fillModMenuFrom( string menuName
                                     , mm_ItemInfo itemInfo
                                     , out array<OptionMenuItem> target
                                     )
  {
    let descriptor = getDescriptor(menuName);
    foreach (item : descriptor.mItems)
    {
      if (!itemInfo.isModded(item)) continue;
      if (item is "OptionMenuItemmm_Injector") continue;
      if (item is "OptionMenuItemStaticText") continue;

      // If it's a submenu, replace it with shortened version.
      let menu = OptionMenuItemSubmenu(item);
      target.push(menu == NULL ? item : new("mm_ShortenedSubmenu").init(menu.mLabel, menu.mAction));
    }
  }

  /// For each "open menu" entry in Controls, creates an item in target.
  private static void addMenusFromKeys(out array<OptionMenuItem> target)
  {
    // Searches for controls that have an action that contains "open" and "menu"
    // and puts creates a corresponding item in target.

    let keysMenuDescriptor = getDescriptor("CustomizeControls");
    int itemsCount = keysMenuDescriptor.mItems.size();
    for (int i = 0; i < itemsCount; ++i)
    {
      let item = keysMenuDescriptor.mItems[i];
      if (!(item is "OptionMenuItemControlBase")) continue;

      string itemAction = item.mAction;
      itemAction = itemAction.makeLower();
      bool isOpenMenu = (itemAction.indexOf("open") != -1 && itemAction.indexOf("menu") != -1);
      if (!isOpenMenu) continue;
      if (itemAction == "openmenu mm_options") continue;

      target.push(new("OptionMenuItemCommand").init(item.mLabel, item.mAction));
    }
  }

  /// Searches the main menu for options.
  private static void addMenuFromMain(out array<OptionMenuItem> target)
  {
    let mainDescriptor = ListMenuDescriptor(MenuDescriptor.getDescriptor("MainMenu"));
    if (mainDescriptor == NULL) return;

    int count = mainDescriptor.mItems.size();
    for (int i = 0; i < count; ++i)
    {
      string anAction = mainDescriptor.mItems[i].mAction;
      if (anAction ~== "PlayerClassMenu" || anAction ~== "OptionsMenu") continue;

      let descriptor = getDescriptor(anAction);
      if (descriptor == NULL) continue;

      string title = descriptor.mTitle.length() ? descriptor.mTitle : anAction;
      target.push(new("mm_ShortenedSubmenu").init(title, anAction));
    }
  }

  /// Adds user-defined menus to target, if they are loaded.
  private static void addNotListedMenus(out array<OptionMenuItem> target)
  {
    for (int lumpIndex = Wads.findLump("more-menus");
         lumpIndex != -1;
         lumpIndex = Wads.findLump("more-menus", lumpIndex + 1))
    {
      string dictionaryString = Wads.readLump(lumpIndex);
      if (dictionaryString.length() == 0 || dictionaryString.left(1) != "{") continue;
      let menus = Dictionary.fromString(dictionaryString);

      let i = DictionaryIterator.create(menus);
      while (i.next())
      {
        string menu = i.key();
        let descriptor = getDescriptor(menu);
        if (descriptor == NULL) continue;

        string menuName = i.value();
        target.push(new("mm_ShortenedSubmenu").init(menuName, menu));
      }
    }
  }

  /// Removes duplicate items, so every entry occurs only once.
  private static void removeDuplicates(out array<OptionMenuItem> items)
  {
    int itemsCount = items.size();
    for (int i = itemsCount - 1; i >= 0; --i)
    {
      for (int j = i - 1; j >= 0; --j)
      {
        if (items[i].mAction == items[j].mAction)
        {
          items.delete(i);
          break;
        }
      }
    }
  }

} // class mm_Builder

/// This class is a submenu that watches for words in its label like "options",
/// "settings", etc, and removes them.
class mm_ShortenedSubmenu : OptionMenuItemSubmenu
{

  OptionMenuItem init(string label, Name command)
  {
    mOriginalLabel = label;
    Super.init(label, command);
    return self;
  }

  override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
  {
    // Note the spaces!
    static const string toRemoves[] =
    {
      " options"   , " Options"   , " OPTIONS",
      " settings"  , " Settings"  , " SETTINGS",
      "customize " , "Customize " , "CUSTOMIZE "
    };

    mLabel = mOriginalLabel;

    string translatedLabel = StringTable.localize(mOriginalLabel);

    int removesCount = toRemoves.size();
    for (int i = 0; i < removesCount; ++i)
    {
      string toRemove = toRemoves[i];
      if (translatedLabel.indexOf(toRemove) != -1 && translatedLabel != toRemove)
      {
        translatedLabel.replace(toRemove, "");
        mLabel = translatedLabel;
        break;
      }
    }

    return Super.draw(desc, y, indent, selected);
  }

  private string mOriginalLabel;

} // class mm_ShortenedSubmenu

class mm_ItemInfo ui
{

  mm_ItemInfo init()
  {
    int fullMenuDefLumpIndex   = Wads.findLump("menudef");
    int simpleMenuDefLumpIndex = Wads.findLump("menudef", fullMenudefLumpIndex + 1);
    mMenuDefContents           = Wads.readLump(fullMenudefLumpIndex)
                              .. Wads.readLump(simpleMenudefLumpIndex);

    return self;
  }

  bool isModded(OptionMenuItem item)
  {
    return (mMenuDefContents.indexOf(item.mLabel) == -1);
  }

  private string mMenuDefContents;

} // class mm_ItemInfo
