// SPDX-FileCopyrightText: 2022 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

version 4.8

class OptionMenuItemmm_Submenu : OptionMenuItemSubmenu
{
  override void onMenuCreated()
  {
    processMenu("OptionsMenu");
    processMenu("OptionsMenuSimple");

    addMenusFromKeys();
    removeDuplicates();
  }

  // private: //////////////////////////////////////////////////////////////////////////////////////

  private void processMenu(string menuName)
  {
    let descriptor = getDescriptor(menuName);
    int modsStart  = findModsStart(descriptor);

    fillModMenuFrom(descriptor, modsStart);
    replaceModOptionsWithSelf(descriptor, modsStart);
  }

  private static OptionMenuDescriptor getDescriptor(Name aName)
  {
    return OptionMenuDescriptor(MenuDescriptor.getDescriptor(aName));
  }

  private static int findModsStart(OptionMenuDescriptor descriptor)
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

  private static void fillModMenuFrom(OptionMenuDescriptor descriptor, int modsStart)
  {
    let modMenuDescriptor = getDescriptor("mm_Options");
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

  private static void addMenusFromKeys()
  {
    // Hack territory!
    let keysMenuDescriptor = getDescriptor("CustomizeControls");
    let modMenuDescriptor  = getDescriptor("mm_Options");
    int itemsCount = keysMenuDescriptor.mItems.size();
    for (int i = 0; i < itemsCount; ++i)
    {
      let item = keysMenuDescriptor.mItems[i];
      if (!(item is "OptionMenuItemControlBase")) continue;

      string itemAction = item.mAction;
      itemAction = itemAction.makeLower();
      bool isOpenMenu = (itemAction.indexOf("open") != -1 && itemAction.indexOf("menu") != -1);
      if (!isOpenMenu) continue;

      let submenu = new("OptionMenuItemCommand");
      submenu.init(item.mLabel, item.mAction);
      modMenuDescriptor.mItems.push(submenu);
    }
  }

  private static void removeDuplicates()
  {
    let modMenuDescriptor = getDescriptor("mm_Options");
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

  private void replaceModOptionsWithSelf(OptionMenuDescriptor descriptor, int modsStart)
  {
    descriptor.mItems.delete(modsStart, descriptor.mItems.size());
    descriptor.mItems.push(self);
  }
}
