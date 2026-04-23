// import {$axiosBack} from "@/api/client.ts";
import { useAxiosRequest } from "@/composables/client";


interface Product {
    id: string
    type: string
    productname: string
    finalprice: number
    hqagentprice: number
    lv1agentprice: number
    lv2agentprice: number
    publishstatus: boolean
    description: string
    createdat: string
}

interface ListProductResponse {
    data: Array<Product>
}

async function listProduct() {
    return await useAxiosRequest({
        url: "/product/list",
        method: "get"
    })
}

async function listPublishedProduct() {
    return await useAxiosRequest({
        url: "/product/published/list",
        method: "get"
    })
}

interface MyProductWithPrice {
    id: string
    productname: string
    finalprice: string
    description: string
    inventoryprice: string
}

interface ListMyProductWithPriceResponse {
    data: Array<MyProductWithPrice>
}

async function listMyProductWithPrice() {
    return await useAxiosRequest({
        url: "/product/current/list/price",
        method: "get"
    })
}

interface MyPurchasedProduct {
    id: number;
    payat: Date | null; // Using Date to represent the timestamp, null to allow for possible unset value
    productname?: string; // Optional field
    description?: string; // Optional field
}

interface MyPurchasedProductResponse {
    data: Array<MyPurchasedProduct>
}

async function listMyPurchasedProduct() {
    return await useAxiosRequest({
        url: "/product/purchased",
        method: "get"
    })
}

interface MyPurchasableProduct {
    id: number;
    productname?: string; // Optional field
    description?: string; // Optional field
}

interface MyPurchasableProductResponse {
    data: Array<MyPurchasedProduct>
}

async function listMyPurchasableProduct() {
    return await useAxiosRequest({
        url: "/product/purchasable",
        method: "get"
    })
}

interface GetProductResponse {
    data: GetProductRow
}

interface GetProductRow extends Product {
    conversionaward: string
}

async function getProduct(productId: string) {
    return await useAxiosRequest({
        url: "/product/" + productId,
        method: "get"
    })
}

interface ProductImage {
    id: string
    imageorder: number
    imagestatus: boolean
    imageurl: string
    ismaster: null | boolean
    productid: string
}

interface ListProductImagesResponse {
    data: Array<ProductImage>
}

async function listProductImages(productId: string) {
    return await useAxiosRequest({
        url: "/product/" + productId + "/images",
        method: "get"
    })
}

export {listProductImages};
export {type ListProductImagesResponse};
export {type ProductImage};
export {getProduct};
export {type GetProductResponse};
export {listMyPurchasableProduct};
export {type MyPurchasableProductResponse};
export {type MyPurchasableProduct};
export {listMyPurchasedProduct};
export {type MyPurchasedProductResponse};
export {type MyPurchasedProduct};
export {listMyProductWithPrice};
export {type ListMyProductWithPriceResponse};
export {type MyProductWithPrice};
export {listProduct};
export {listPublishedProduct};
export {type ListProductResponse};
export {type Product};
export {type GetProductRow};