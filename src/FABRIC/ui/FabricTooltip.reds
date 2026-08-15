module FABRIC

@addField(AGenericTooltipControllerWithDebug)
private let m_fabricOutfitUsage: ref<FabricOutfitUsageTooltip>;

/**
 * Owns FABRIC's lazily attached saved-outfit section for one reusable vanilla tooltip.
 *
 * The host controller owns this widget; the section remains hidden unless the current cache has
 * associations for the bound item.
 */
public class FabricOutfitUsageTooltip extends inkFlex {
  private let m_divider: ref<inkRectangle>;
  private let m_title: ref<inkText>;
  private let m_names: ref<inkText>;
  private let m_isAttached: Bool;

  /**
   * Creates one hidden FABRIC section for a supported vanilla tooltip controller.
   *
   * @param controller The host tooltip controller that owns the added section.
   * @return None.
   * @errors A missing controller or existing section leaves the host unchanged.
   */
  public static final func Initialize(controller: ref<AGenericTooltipControllerWithDebug>) -> Void {
    let section: ref<FabricOutfitUsageTooltip>;
    let wrapper: ref<inkVerticalPanel>;
    let divider: ref<inkRectangle>;
    let title: ref<inkText>;
    let names: ref<inkText>;

    if !IsDefined(controller) || IsDefined(controller.m_fabricOutfitUsage) {
      return;
    }

    section = new FabricOutfitUsageTooltip();
    section.SetName(n"fabricOutfitUsage");
    section.SetMargin(20.0, 0.0, 0.0, 15.0);
    section.SetFitToContent(true);
    section.SetVisible(false);

    wrapper = new inkVerticalPanel();
    wrapper.SetName(n"wrapper");
    wrapper.SetHAlign(inkEHorizontalAlign.Left);
    wrapper.SetVAlign(inkEVerticalAlign.Center);
    wrapper.SetFitToContent(true);

    divider = new inkRectangle();
    divider.SetName(n"fabricOutfitUsageDivider");
    divider.SetSize(new Vector2(654.0, 2.0));
    divider.SetMargin(0.0, 0.0, 0.0, 12.0);
    divider.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
    divider.BindProperty(n"tintColor", n"MainColors.Red");
    divider.SetOpacity(0.04);

    title = new inkText();
    title.SetName(n"fabricOutfitUsageTitle");
    title.SetText("OUTFITS:");
    title.SetTintColor(new HDRColor(0.5, 1.0, 0.5, 1.0));
    title.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    title.SetFontStyle(n"Semi-Bold");
    title.SetFontSize(28);

    names = new inkText();
    names.SetName(n"fabricOutfitUsageNames");
    names.SetTintColor(new HDRColor(1.0, 1.0, 1.0, 1.0));
    names.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    names.SetFontStyle(n"Medium");
    names.SetFontSize(28);
    names.SetMargin(10.0, 0.0, 0.0, 0.0);

    section.m_divider = divider;
    section.m_title = title;
    section.m_names = names;
    wrapper.AddChildWidget(divider);
    wrapper.AddChildWidget(title);
    wrapper.AddChildWidget(names);
    section.AddChildWidget(wrapper);
    controller.m_fabricOutfitUsage = section;
  }

  /**
   * Resolves and displays the current outfit names for one tooltip item binding.
   *
   * @param root The host tooltip root used for lazy attachment.
   * @param itemID The exact or catalog item identity to query.
   * @param useRecordLookup True for catalog data; false for owned item data.
   * @return None.
   * @errors Missing cache data, names, or attachment target hides the FABRIC section.
   */
  public final func Update(root: inkWidgetRef, itemID: ItemID, useRecordLookup: Bool) -> Void {
    let service = FabricService.Get();
    let names: array<String>;

    if !IsDefined(service) {
      this.SetVisible(false);
      return;
    }

    if useRecordLookup {
      names = service.GetAssociatedOutfitNamesByRecord(itemID);
    } else {
      names = service.GetAssociatedOutfitNames(itemID);
    }
    if ArraySize(names) == 0 {
      this.SetVisible(false);
      return;
    }

    this.Attach(root);
    if !this.m_isAttached {
      this.SetVisible(false);
      return;
    }

    this.SortNames(names);
    this.m_title.SetText(s"OUTFITS (\(ArraySize(names))):");
    this.m_names.SetText(this.FormatNames(names));
    this.SetVisible(true);
  }

  /**
   * Attaches this section once when the host tooltip exposes its standard categories container.
   *
   * @param root The host tooltip root that may contain the categories panel.
   * @return None.
   * @errors A missing root or panel leaves the section detached and hidden on the caller's path.
   */
  private final func Attach(root: inkWidgetRef) -> Void {
    let tooltipRoot = inkWidgetRef.Get(root) as inkFlex;
    let sectionRoot: ref<inkVerticalPanel>;

    if !IsDefined(tooltipRoot) {
      return;
    }

    sectionRoot = tooltipRoot.GetWidgetByPathName(
      n"contentWrapper/contentFlexWrapper/categoriesWrapper") as inkVerticalPanel;

    if IsDefined(sectionRoot) {
      this.m_divider.SetSize(new Vector2(654.0, 2.0));
      this.m_divider.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
      this.m_divider.BindProperty(n"tintColor", n"MainColors.Red");
      this.m_divider.SetOpacity(0.04);

      if !this.m_isAttached {
        this.Reparent(sectionRoot, 8);
        this.m_isAttached = true;
      }
    }
  }

  /**
   * Sorts the mutable display-name array alphabetically without querying game data.
   *
   * @param names The outfit-name array to reorder in place.
   * @return None.
   * @errors None; empty arrays remain empty.
   */
  private final func SortNames(out names: array<String>) -> Void {
    let index: Int32 = 1;
    let previousIndex: Int32;
    let value: String;

    while index < ArraySize(names) {
      value = names[index];
      previousIndex = index - 1;
      while previousIndex >= 0 && StrCmp(names[previousIndex], value) > 0 {
        names[previousIndex + 1] = names[previousIndex];
        previousIndex -= 1;
      }
      names[previousIndex + 1] = value;
      index += 1;
    }
  }

  /**
   * Joins sorted outfit names into the multi-line text required by the Ink label.
   *
   * @param names The ordered display names to join.
   * @return One newline-delimited string, or an empty string for no names.
   * @errors None.
   */
  private final func FormatNames(names: array<String>) -> String {
    let result: String;
    let index: Int32;

    while index < ArraySize(names) {
      if index > 0 {
        result += "\n";
      }
      result += names[index];
      index += 1;
    }

    return result;
  }
}

/**
 * Creates FABRIC's section only for tooltip controllers with supported item data bindings.
 *
 * @param None.
 * @return The original host initialization result.
 * @errors Unsupported controllers retain their native initialization without a FABRIC section.
 */
@wrapMethod(AGenericTooltipControllerWithDebug)
protected cb func OnInitialize() -> Bool {
  let result = wrappedMethod();

  if IsDefined(this as ItemTooltipCommonController) || IsDefined(this as NewItemTooltipCommonController) {
    FabricOutfitUsageTooltip.Initialize(this);
  }

  return result;
}

/**
 * Updates or clears FABRIC's section after the host binds a standard tooltip payload.
 *
 * @param tooltipData The host payload describing an owned or catalog item.
 * @return None.
 * @errors Unsupported payloads hide prior FABRIC state and preserve native tooltip behavior.
 */
@wrapMethod(ItemTooltipCommonController)
public func SetData(tooltipData: ref<ATooltipData>) -> Void {
  wrappedMethod(tooltipData);

  if !IsDefined(this.m_fabricOutfitUsage) {
    return;
  }

  if IsDefined(tooltipData as UIInventoryItemTooltipWrapper) {
    this.m_fabricOutfitUsage.Update(
      this.m_root, (tooltipData as UIInventoryItemTooltipWrapper).m_data.GetID(), false);
  } else {
    if IsDefined(tooltipData as InventoryTooltipData) {
      this.m_fabricOutfitUsage.Update(
        this.m_root, (tooltipData as InventoryTooltipData).itemID, true);
    } else {
      this.m_fabricOutfitUsage.SetVisible(false);
    }
  }
}
