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
   * Builds the contens of Mod Menu by collecting items from the full options
   * menu, simple options menu, and from controls menu, and makes sure that
   * there are no duplicates.
   */
  static void build()
  {
    fillModMenuFrom(FULL_OPTIONS_MENU);
    fillModMenuFrom(SIMPLE_OPTIONS_MENU);

    addMenusFromKeys();

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
    // Consider everything that has matching text in the first two menudefs
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
        modMenuDescriptor.mItems.push(item);
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

      let submenu = new("OptionMenuItemCommand");
      submenu.init(item.mLabel, item.mAction);
      modMenuDescriptor.mItems.push(submenu);
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
 * Mod Menu itself. The init function makes sure that the Mod Menu contens are
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
