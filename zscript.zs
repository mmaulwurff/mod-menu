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
    if (descriptor == NULL) return;
    int officialEnd = findOfficialEnd(descriptor);

    fillModMenuFrom(descriptor, officialEnd);
    replaceModOptionsWithSelf(descriptor, officialEnd);
  }

  private static OptionMenuDescriptor getDescriptor(Name aName)
  {
    return OptionMenuDescriptor(MenuDescriptor.getDescriptor(aName));
  }

  private static int findOfficialEnd(OptionMenuDescriptor descriptor)
  {
    int itemsCount = descriptor.mItems.size();
    for (int i = 0; i < itemsCount; ++i)
    {
      let item = descriptor.mItems[i];
      if (item.mLabel == "$OPTMNU_CONSOLE") return i;
    }

    return itemsCount;
  }

  private static void fillModMenuFrom(OptionMenuDescriptor descriptor, int officialEnd)
  {
    let modMenuDescriptor = getDescriptor("mm_Options");
    int itemsCount = descriptor.mItems.size();
    for (int i = officialEnd + 1; i < itemsCount; ++i)
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

  private void replaceModOptionsWithSelf(OptionMenuDescriptor descriptor, int officialEnd)
  {
    descriptor.mItems.delete(officialEnd + 2, descriptor.mItems.size());
    descriptor.mItems.push(self);
  }
}
