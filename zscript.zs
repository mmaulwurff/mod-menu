// SPDX-FileCopyrightText: 2022 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

version 4.8

/// The core of Mod Menu. It builds the contents of Mod Menu.
class OptionMenuItemmm_Injector : OptionMenuItem
{

  const FULL_OPTIONS_MENU   = "OptionsMenu";
  const SIMPLE_OPTIONS_MENU = "OptionsMenuSimple";
  const MOD_MENU            = "mm_Options";

  void init() {}

  /// Is called when Options Menu is created, it fills the Mod Menu and modifies
  /// the Options Menu.
  override void onMenuCreated()
  {
    let  modMenuDescriptor = build();
    bool hasModMenus = modMenuDescriptor.mItems.size() != 0;

    modifyMenu(FULL_OPTIONS_MENU,   hasModMenus);
    modifyMenu(SIMPLE_OPTIONS_MENU, hasModMenus);
  }

  /// Builds the contents of Mod Menu by collecting items from the full options
  /// menu, simple options menu, and from controls menu, and makes sure that
  /// there are no duplicates.
  static OptionMenuDescriptor build()
  {
    let modMenuDescriptor = getDescriptor(MOD_MENU);

    fillModMenuFrom(FULL_OPTIONS_MENU,   modMenuDescriptor.mItems);
    fillModMenuFrom(SIMPLE_OPTIONS_MENU, modMenuDescriptor.mItems);

    addMenusFromKeys (modMenuDescriptor.mItems);
    addNotListedMenus(modMenuDescriptor.mItems);
    addMenuFromMain  (modMenuDescriptor.mItems);

    // Not only removes duplicates that appear from different menus, but also
    // from consequent calls of build().
    removeDuplicates(modMenuDescriptor.mItems);

    return modMenuDescriptor;
  }

  /// Replaces mod menus with Mod Menu.
  private void modifyMenu(string menuName, bool hasModMenus)
  {
    let optionsDescriptor = getDescriptor(menuName);
    if (hasModMenus)
    {
      // Remove everything mod-related and add Mod Menu.
      int modsStart = findModsStart(optionsDescriptor);
      optionsDescriptor.mItems.delete(modsStart, optionsDescriptor.mItems.size());
      optionsDescriptor.mItems.push(new("OptionMenuItemSubmenu").init("$MM_OPTIONS", MOD_MENU));
    }
    else
    {
      // Remove the last item. There is no other mods, so it must be the injector.
      optionsDescriptor.mItems.pop();
    }
  }

  /// Returns option menu descriptor by the menu name.
  private static OptionMenuDescriptor getDescriptor(Name aName)
  {
    return OptionMenuDescriptor(MenuDescriptor.getDescriptor(aName));
  }

  /// Finds the index of the first non-standard options menu element.
  private static int findModsStart(OptionMenuDescriptor descriptor)
  {
    // Consider everything that has matching text in the first two menudef lumps
    // (full and simple options) 'official'.
    int    fullMenudefLumpIndex   = Wads.findLump("menudef");
    int    simpleMenudefLumpIndex = Wads.findLump("menudef", fullMenudefLumpIndex + 1);
    string menudefContents        = Wads.readLump(fullMenudefLumpIndex);
    // Workaround for Wads.readLump returning a zero-terminated string.
    // https://github.com/ZDoom/gzdoom/issues/1715
    menudefContents.deleteLastCharacter();
    menudefContents = menudefContents .. Wads.readLump(simpleMenudefLumpIndex);

    int itemsCount = descriptor.mItems.size();
    for (int i = 0; i < itemsCount; ++i)
    {
      let item = descriptor.mItems[i];
      if (item is "OptionMenuItemStaticText") continue;
      if (item is "OptionMenuItemmm_Injector") return i;
      if (menudefContents.indexOf(item.mLabel) == -1) return i;
    }

    return itemsCount;
  }

  /// Copies non-standard menu items from a menu to target.
  private static void fillModMenuFrom(string menuName, out array<OptionMenuItem> target)
  {
    let descriptor = getDescriptor(menuName);
    int modsStart  = findModsStart(descriptor);

    int itemsCount = descriptor.mItems.size();
    for (int i = modsStart; i < itemsCount; ++i)
    {
      let item = descriptor.mItems[i];
      if (item is "OptionMenuItemStaticText" || item is "OptionMenuItemmm_Injector") continue;
      if (item.mLabel == "$MM_OPTIONS") continue;

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

  /// Adds a number of hard-coded menus to target, if they are loaded.
  private static void addNotListedMenus(out array<OptionMenuItem> target)
  {
    static const string menus[] =
    {
      "FinalDoomer", "Final Doomer +",
      "ParryDooMConfig", "ParryDooM"
    };

    int count = menus.size();
    for (int i = 0; i < count; i += 2)
    {
      string menu = menus[i];
      let descriptor = getDescriptor(menu);
      if (descriptor == NULL) continue;

      string menuName = menus[i + 1];
      target.push(new("OptionMenuItemSubmenu").init(menuName, menu));
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

} // class OptionMenuItemmm_Injector

/// Mod Menu itself. The init function makes sure that the Mod Menu contents are
/// built before it is shown.
class mm_Menu : OptionMenu
{

  override void init(Menu parent, OptionMenuDescriptor descriptor)
  {
    Super.init(parent, descriptor);

    // Fills the Mod Menu even when it is opened before mm_Submenu is
    // instantiated: when the game is started without opening an options menu,
    // and then Mod Menu is opened via a bound key.
    OptionMenuItemmm_Injector.build();
  }

} // class mm_Menu

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
