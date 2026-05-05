import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { ProductDetailView } from "@/components/product-detail-view";
import {
  loadHighlightCatalog,
  loadKitCatalog,
  loadProductById,
} from "@/lib/catalog/load-shop-data";
import { distinctProductSubtitle } from "@/lib/catalog/parse-product";

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const product = await loadProductById(id);
  if (!product) return { title: "Product" };

  return {
    title: product.title,
    description: distinctProductSubtitle(product) ?? undefined,
  };
}

export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const [product, highlightCatalog, kitCatalog] = await Promise.all([
    loadProductById(id),
    loadHighlightCatalog(),
    loadKitCatalog(),
  ]);

  if (!product) notFound();

  return (
    <ProductDetailView
      product={product}
      highlightCatalog={highlightCatalog}
      kitCatalog={kitCatalog}
    />
  );
}
