# Second character

Preserve all four original golden-character textures and keep that character as the default. Add an original Japanese anime character with blue hime-cut hair, a reserved graceful presence and a gentle sweet expression. Match the existing right-aligned composition and quiet background.

Both macOS and Windows controls select and persist the character alongside the four existing appearance values. Old settings keep the golden character. Switching preserves the animation clock and appearance; explicit Replay alone restarts the introduction. Both characters blink and move their hair during the reveal and settled animation. Reduce Motion remains static. No new runtime dependencies.

Use character-specific eye and hair geometry. Derive the new character's linework in the renderer from its open/closed textures. Keep the previous character visible until replacement textures are ready, and release superseded GPU resources. Unknown character identifiers fall back to golden.

Acceptance: unchanged original asset hashes; settings migration/round trips on both hosts; renderer switching/race tests and one-shot regressions; native build checks; browser visual verification of blue open/closed eyes, hair motion and reveal. Document any platform validation limits.
