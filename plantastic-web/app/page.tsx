import { HomeShop } from "@/components/home-shop";
import {
  loadHighlightCatalog,
  loadShopHomeBanner,
  loadShopProducts,
} from "@/lib/catalog/load-shop-data";

export default async function Home() {
  const [products, banner, highlightCatalog] = await Promise.all([
    loadShopProducts(),
    loadShopHomeBanner(),
    loadHighlightCatalog(),
  ]);

  return (
    <HomeShop
      products={products}
      banner={banner}
      highlightCatalog={highlightCatalog}
    />
  );
}
