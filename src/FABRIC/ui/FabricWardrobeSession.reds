module FABRIC

/**
 * Owns FABRIC's transient wardrobe-UI scope for one game session.
 *
 * FabricService owns this collaborator. UI adapters must use it only to avoid applying wardrobe
 * presentation in unrelated inventory contexts.
 */
public class FabricWardrobeSession extends IScriptable {
  private let m_isActive: Bool;

  /**
   * Starts the wardrobe presentation session before the host creates virtualized cards.
   * @param None.
   * @return None; marks this session active.
   * @errors None.
   */
  public final func Begin() -> Void { this.m_isActive = true; }

  /**
   * Ends the wardrobe presentation session after the host has completed its close behavior.
   * @param None.
   * @return None; marks this session inactive.
   * @errors None; ending an inactive session is safe.
   */
  public final func End() -> Void { this.m_isActive = false; }

  /**
   * Reports whether card adapters may apply wardrobe-scoped FABRIC presentation.
   * @param None.
   * @return True while the session is active; otherwise false.
   * @errors None.
   */
  public final func IsActive() -> Bool { return this.m_isActive; }
}
