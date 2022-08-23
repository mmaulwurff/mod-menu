// SPDX-FileCopyrightText: 2022 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

version 4.8

/**
 * The core of Mod Menu. It builds the contents of Mod Menu.
 */
class mm_Builder : OptionMenuItem
{

  const FULL_OPTIONS_MENU   = "OptionsMenu";
  const SIMPLE_OPTIONS_MENU = "OptionsMenuSimple";
  const MOD_MENU            = "mm_Options";

  /**
   * Builds the contents of Mod Menu by collecting items from the full options
   * menu, simple options menu, and from controls menu, and makes sure that
   * there are no duplicates.
   */
  static void build()
  {
    fillModMenuFrom(FULL_OPTIONS_MENU);
    fillModMenuFrom(SIMPLE_OPTIONS_MENU);

    addMenusFromKeys();
    addNotListedMenus();

    // Not only removes duplicates that appear from different menus, but also
    // from consequent calls of build().
    removeDuplicates();
  }

  /**
   * Returns option menu descriptor by the menu name.
   */
  static OptionMenuDescriptor getDescriptor(Name aName)
  {
    return OptionMenuDescriptor(MenuDescriptor.getDescriptor(aName));
  }

  /**
   * Finds the index of the first non-standard options menu element.
   */
  static int findModsStart(OptionMenuDescriptor descriptor)
  {
    // Consider everything that has matching text in the first two menudef lumps
    // (full and simple options) 'official'.
    int    fullMenudefLumpIndex   = Wads.findLump("menudef");
    int    simpleMenudefLumpIndex = Wads.findLump("menudef", fullMenudefLumpIndex + 1);
    string menudefContents = Wads.readLump(fullMenudefLumpIndex);
    // Workaround for Wads.readLump returning a zero-terminated string.
    // https://github.com/ZDoom/gzdoom/issues/1715
    menudefContents.deleteLastCharacter();
    menudefContents = menudefContents .. Wads.readLump(simpleMenudefLumpIndex);

    int itemsCount = descriptor.mItems.size();
    for (int i = 0; i < itemsCount; ++i)
    {
      let item = descriptor.mItems[i];
      if (item is "OptionMenuItemStaticText") continue;
      if (menudefContents.indexOf(item.mLabel) == -1) return i;
    }

    return itemsCount;
  }

  // private: //////////////////////////////////////////////////////////////////////////////////////

  /**
   * Copies non-standard menu items from a menu to Mod Menu.
   */
  private static void fillModMenuFrom(string menuName)
  {
    let descriptor = getDescriptor(menuName);
    int modsStart  = findModsStart(descriptor);

    let modMenuDescriptor = getDescriptor(MOD_MENU);
    int itemsCount = descriptor.mItems.size();
    for (int i = modsStart; i < itemsCount; ++i)
    {
      let item = descriptor.mItems[i];
      if (!(item is "OptionMenuItemStaticText") && item.mLabel != "$MM_OPTIONS")
      {
        // If it's a submenu, replace it with shortened version.
        let menu = OptionMenuItemSubmenu(item);
        modMenuDescriptor.mItems.push(menu == NULL
          ? item
          : new("ShortenedSubmenu").init(menu.mLabel, menu.mAction, menu.mParam, menu.mCentered));
      }
    }
  }

  /**
   * For each "open menu" entry in Controls, creates an entry in Mod Menu.
   */
  private static void addMenusFromKeys()
  {
    // Searches for controls that have an action that contains "open" and "menu"
    // and puts creates a corresponding entry in Mod Menu.

    let keysMenuDescriptor = getDescriptor("CustomizeControls");
    let modMenuDescriptor  = getDescriptor(MOD_MENU);
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

      modMenuDescriptor.mItems.push(new("OptionMenuItemCommand").init(item.mLabel, item.mAction));
    }
  }

  /**
   * Adds a number of hard-coded menus to the Mod Menu, if they are loaded.
   */
  private static void addNotListedMenus()
  {
    static const string menus[] =
    {
      "FinalDoomer", "Final Doomer +"
    };

    let modMenuDescriptor = getDescriptor(MOD_MENU);

    int count = menus.size();
    for (int i = 0; i < count; i += 2)
    {
      string menu = menus[i];
      let descriptor = getDescriptor(menu);
      if (descriptor == NULL) continue;

      string menuName = menus[i + 1];
      modMenuDescriptor.mItems.push(new("OptionMenuItemSubmenu").init(menuName, menu));
    }
  }

  /**
   * Removes duplicate Mod Menu elements, so every entry occurs only once.
   */
  private static void removeDuplicates()
  {
    let modMenuDescriptor = getDescriptor(MOD_MENU);
    int itemsCount = modMenuDescriptor.mItems.size();
    for (int i = itemsCount - 1; i >= 0; --i)
    {
      for (int j = i - 1; j >= 0; --j)
      {
        if (modMenuDescriptor.mItems[i].mAction == modMenuDescriptor.mItems[j].mAction)
        {
          modMenuDescriptor.mItems.delete(i);
          break;
        }
      }
    }
  }

} // class mm_Builder

/**
 * Mod Menu itself. The init function makes sure that the Mod Menu contents are
 * built before it is shown.
 */
class mm_Menu : OptionMenu
{

  override void init(Menu parent, OptionMenuDescriptor descriptor)
  {
    Super.init(parent, descriptor);

    // This build fills the Mod Menu when it is opened before mm_Submenu is
    // instantiated: when the game is started without opening an options menu,
    // and then Mod Menu is opened via a bound key.
    mm_Builder.build();
  }

} // class mm_Menu

/**
 * This class is a submenu that watches for words in its label like
 * "options", "settings", etc, and removes them.
 */
class ShortenedSubmenu : OptionMenuItemSubmenu
{

  OptionMenuItem init(string label, Name command, int param = 0, bool centered = false)
  {
    mOriginalLabel = label;
    Super.init(label, command, param, centered);
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

} // class ShortenedSubmenu

/**
 * The submenu that leads to Mod Menu.
 */
class OptionMenuItemmm_Submenu : OptionMenuItemSubmenu
{

  /**
   * Is called when Options Menu is created, it fills the Mod Menu and modifies
   * the Options Menu.
   */
  override void onMenuCreated()
  {
    // This build fills the Mod Menu when the Mod Menu is opened from Options
    // Menu.
    mm_Builder.build();

    modifyMenu(mm_Builder.FULL_OPTIONS_MENU);
    modifyMenu(mm_Builder.SIMPLE_OPTIONS_MENU);
  }

  // private: //////////////////////////////////////////////////////////////////////////////////////

  /**
   * Either replaces mod menu entries with itself, or removes itself from
   * Options Menu.
   */
  private void modifyMenu(string menuName)
  {
    let optionsDescriptor = mm_Builder.getDescriptor(menuName);
    let modMenuDescriptor = mm_Builder.getDescriptor(mm_Builder.MOD_MENU);
    if (modMenuDescriptor.mItems.size() == 0)
    {
      // Remove the last item. There is no other mods, so it must be Mod Menu submenu.
      optionsDescriptor.mItems.pop();
    }
    else
    {
      // Remove every mod menu, and put Mod Menu submenu back.
      int modsStart = mm_Builder.findModsStart(optionsDescriptor);
      optionsDescriptor.mItems.delete(modsStart, optionsDescriptor.mItems.size());
      optionsDescriptor.mItems.push(self);
    }
  }

} // class OptionMenuItemmm_Submenu
