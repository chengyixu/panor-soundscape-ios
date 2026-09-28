# Discovery Map Domain

Only soundscapes with valid latitude and longitude become map annotations. The page root always fills and top-aligns within the tab so loading, error, empty, and loaded states keep the same title position. The map consumes most remaining phone height, bounded between 360 and 560 points. Selecting an annotation overlays one title line, cover, location, and a play action without navigating away.

The map reads the same server-filtered Explore contract as the Explore tab. Requests in flight may be shared, but previously fetched public UGC is never reused: on refresh failure the map hides its markers rather than resurfacing a removed or blocked recording.

The persistent search field filters recordings by title, creator, location, category and theme. Search this area applies the camera viewport explicitly (including antimeridian wrapping); panning alone does not discard the results. The result count, Map/List toggle and Show all reset give this surface a clear browse/find/listen flow. This is recording search, not general address geocoding.
