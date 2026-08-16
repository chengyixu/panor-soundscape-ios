# Discovery Map Domain

Only soundscapes with valid latitude and longitude become map annotations. The page root always fills and top-aligns within the tab so loading, error, empty, and loaded states keep the same title position. The map consumes most remaining phone height, bounded between 360 and 560 points. Selecting an annotation overlays one title line, cover, location, and a play action without navigating away.

The map reads the same cached public Explore contract as the Explore tab. A fresh Explore result is reused instead of fetched again; manual retry bypasses freshness, while a bounded stale snapshot keeps markers available during transient backend failures.
