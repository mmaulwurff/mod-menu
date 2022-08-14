// SPDX-FileCopyrightText: 2022 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

version 4.8

class OptionMenuItemmm_Submenu : OptionMenuItemSubmenu
{
  override void onMenuCreated()
  {
    let fullOptionsDescriptor = getDescriptor("OptionsMenu");
    if (fullOptionsDescriptor == NULL) return;
    int officialFullOptionsEnd = findOfficialEnd(fullOptionsDescriptor);
    if (officialFullOptionsEnd == -1) return;
    fillModMenuFrom(fullOptionsDescriptor, officialFullOptionsEnd);
    replaceModOptionsWithSelf(fullOptionsDescriptor, officialFullOptionsEnd);

    let simpleOptionsDescriptor = getDescriptor("OptionsMenuSimple");
    if (simpleOptionsDescriptor == NULL) return;
    int officialSimpleOptionsEnd = findOfficialEnd(simpleOptionsDescriptor);
    if (officialSimpleOptionsEnd == -1) return;
    replaceModOptionsWithSelf(simpleOptionsDescriptor, officialSimpleOptionsEnd);
  }

  // private: //////////////////////////////////////////////////////////////////////////////////////

  private OptionMenuDescriptor getDescriptor(Name aName)
  {
    return OptionMenuDescriptor(MenuDescriptor.getDescriptor(aName));
  }

  private int findOfficialEnd(OptionMenuDescriptor descriptor)
  {
    int itemsCount = descriptor.mItems.size();
    for (int i = 0; i < itemsCount; ++i)
    {
      let item = descriptor.mItems[i];
      if (item.mLabel == "$OPTMNU_CONSOLE") return i;
    }

    return -1;
  }

  private void fillModMenuFrom(OptionMenuDescriptor descriptor, int officialEnd)
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

  private void replaceModOptionsWithSelf(OptionMenuDescriptor descriptor, int officialEnd)
  {
    int itemsCount = descriptor.mItems.size();
    for (int i = officialEnd; i < itemsCount; ++i) descriptor.mItems.delete(officialEnd + 1);

    descriptor.mItems.push(new("OptionMenuItemStaticText"));
    descriptor.mItems.push(self);
  }
}
