//
//  PaymentDTO.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import Foundation

struct CreateOrderRequest: Codable {
    let estate_id: String
    let total_price: Int
}

struct CreateOrderResponse: Codable {
    let order_id: String
    let order_code: String
    let total_price: Int
    let createdAt: String
    let updatedAt: String
}

struct ValidatePaymentRequest: Codable {
    let imp_uid: String
}

struct ValidatePaymentResponse: Codable {
    let payment_id: String
    let order_item: OrderItem
    let createdAt: String
    let updatedAt: String
}

struct OrderItem: Codable {
    let order_id: String
    let order_code: String
    let estate: OrderEstateInfo
    let paidAt: String
    let createdAt: String
    let updatedAt: String
}

struct PaymentGeolocation: Codable {
    let longitude: Double
    let latitude: Double
}

struct OrderEstateInfo: Codable {
    let id: String
    let category: String
    let title: String
    let introduction: String?
    let thumbnails: [String]
    let deposit: Int
    let monthly_rent: Int
    let built_year: String?
    let area: Double
    let floors: Int
    let geolocation: PaymentGeolocation
    let createdAt: String
    let updatedAt: String
}
