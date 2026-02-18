import { useEffect, useRef } from "react";
import maplibregl from "maplibre-gl";
import * as pmtiles from "pmtiles";

export default function Map() {
  const mapRef = useRef<maplibregl.Map | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    const protocol = new pmtiles.Protocol();
    maplibregl.addProtocol("pmtiles", protocol.tile);

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: import.meta.env.VITE_STYLE_URL,
      center: [2.35, 47],
      zoom: 5,
    });

    const popup = new maplibregl.Popup({
      closeButton: false,
      closeOnClick: false,
      className: 'price-popup',
      anchor: 'bottom',
      offset: [0, -10]
    });

    map.on("load", () => {
      mapRef.current = map;

      map.on("mousemove", "price-fill", (e) => {
        if (e.features && e.features.length > 0) {
          const feature = e.features[0];

          const featureId = feature.properties.id || "";

          // Apply filter to the highlight layer to only show the hovered polygon
          map.setFilter("price-highlight", ["==", ["get", "id"], featureId]);

          // --- POPUP LOGIC ---
          const price_maison = feature.properties.price_estimate ? Math.round(feature.properties.price_estimate).toLocaleString('fr-FR') + " €" : 'N/A'
          const price_appartement = feature.properties.price_estimate_appartement ? Math.round(feature.properties.price_estimate_appartement).toLocaleString('fr-FR') + " €" : 'N/A';

          popup
            .setLngLat(e.lngLat)
            .setHTML(`<div>${feature.properties.name}<div class="price-label">Maison: ${price_maison}</div><div class="price-label">Appartement: ${price_appartement}</div></div>`)
            .addTo(map);

          map.getCanvas().style.cursor = "pointer";
        }
      });

      map.on("mouseleave", "price-fill", () => {
        // Reset filter so nothing is highlighted
        map.setFilter("price-highlight", ["==", ["get", "id"], ""]);

        popup.remove();
        map.getCanvas().style.cursor = "";
      });
    });

    return () => map.remove();
  }, []);

  return (
    <>
      <div ref={containerRef} style={{ height: "100vh", width: "100%" }} />
      <style>{`
        .price-popup .maplibregl-popup-content {
          background-color: #000000;
          color: #ffffff;
          padding: 8px 12px;
          border-radius: 0px;
        }
        .price-label {
          font-size: 20px;
          font-weight: 900;
        }
        .maplibregl-popup-tip {
          border-top-color: #000000 !important;
        }
      `}</style>
    </>
  );
}
