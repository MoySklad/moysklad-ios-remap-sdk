//
//  Money.swift
//  Money
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Daniel Thorpe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import Foundation
//import ValueCoding

/**
 
 # MoneyType
 
 `MoneyType` is a protocol which refines `DecimalNumberType`. It
 adds a generic type for the currency.
*/
public protocol MoneyType: DecimalNumberType, ValueCoding {
    associatedtype Currency: CurrencyType

    /// Access the underlying decimal
    var decimal: _Decimal<Currency> { get }

    /// Access the underlying minor units
    var minorUnits: IntegerLiteralType { get }

    /// Initialize the money with a decimal
    init(_: _Decimal<Currency>)

    /// Initialize the money with a integer representing minor units
    init(minorUnits: IntegerLiteralType)
}

public extension MoneyType {

    /// - returns: a String for the currency's international code.
    var currencyCode: String {
        return Currency.code
    }

    /// - returns: a String for the currency's symbol in the current locale.
    var currencySymbol: String? {
        return Currency.symbol
    }
}

public extension MoneyType where DecimalStorageType == NSDecimalNumber {

    /// Convenience access to the "amount" as an NSDecimalNumber.
    var amount: DecimalStorageType {
        return storage
    }

    /**

     ### Formatted String

     This function will format the Money type into a string for 
     the current locale.

     For custom currencies which define their own currency code,
     create a lazy static `NSNumberFormatter`. Set the following
     properties on it: `currencySymbol`, `internationalCurrencySymbol`
     `currencyGroupingSeparator` and `currencyDecimalSeparator`, as they
     will be used when formatting the string. Feel free to fall back to
     the current locale's values for any of these to maintain
     natural looking formatting. See the example project for more.

     - parameter style: the `NSNumberFormatterStyle` to use.
     - returns: a localized and formatted string for the money amount.
     */
    func formatted(withStyle style: NumberFormatter.Style) -> String {
        return Currency.formatted(withStyle: style, andLocaleId: Locale.current.identifier)(amount)
    }

    /**

     ### Formatted String for specific Locale

     This function will format the Money type into a string suitable
     for a specific local. It accepts an parameter for the
     style `NSNumberFormatterStyle`. Note that iOS 9 and OS X 10.11
     added new styles which are relevant for currency.

     These are `.CurrencyISOCodeStyle`, `.CurrencyPluralStyle`, and
     `.CurrencyAccountingStyle`.

     - parameter style: the `NSNumberFormatterStyle` to use.
     - parameter locale: a `Locale` value
     - returns: a localized and formatted string for the money amount.
     */
    func formatted(withStyle style: NumberFormatter.Style, andLocalization localization: Localization) -> String {
        return Currency.formatted(withStyle: style, andLocalization: localization)(amount)
    }
}

public extension MoneyType where DecimalStorageType == BankersDecimal.DecimalStorageType {

    /**
     Use a `BankersDecimal` to convert the receive into another `MoneyType`. To use this
     API the underlying `DecimalStorageType`s between the receiver, the other `MoneyType`
     must both be the same a that of `BankersDecimal` (which luckily they are).

     - parameter rate: a `BankersDecimal` representing the rate.
     - returns: another `MoneyType` value.
     */
    func convert<Other: MoneyType>(withRate rate: BankersDecimal) -> Other where Other.DecimalStorageType == BankersDecimal.DecimalStorageType {
        return multiply(by: Other(storage: rate.storage))
    }
}

/**

 # Money

 `_Money` is a value type, conforming to `MoneyType`, which is generic over the currency type.
 
 To work in whatever the local currency is, use `Money`. It should not
 be necessary to use `_Money` directly, instead, use a typealias, 
 such as `USD` or `GBP`.
*/
public struct _Money<C: CurrencyType>: MoneyType {
    public typealias Magnitude = _Decimal<C>
    
    public static func -=(lhs: inout _Money<C>, rhs: _Money<C>) {
        lhs = lhs.subtract(rhs)
    }
    
    public static func +=(lhs: inout _Money<C>, rhs: _Money<C>) {
        lhs = lhs.add(rhs)
    }
    
    public static func *=(lhs: inout _Money<C>, rhs: _Money<C>) {
        lhs = lhs.multiply(by: rhs)
    }
    
    public init?<T>(exactly source: T) where T : BinaryInteger {
        decimal = _Decimal<DecimalNumberBehavior>(integerLiteral: Int(source))
        magnitude = decimal.isNegative ? decimal.negative : decimal
    }
    
    public static func *(lhs: _Money<C>, rhs: _Money<C>) -> _Money<C> {
        return lhs.multiply(by: rhs)
    }
    
    public static func +=(lhs: inout _Money<C>, rhs: _Money<C>) -> _Money<C> {
        return lhs.add(rhs)
    }
    
    public static func -=(lhs: inout _Money<C>, rhs: _Money<C>) -> _Money<C> {
        return lhs.subtract(rhs)
    }
    
    public static prefix func +(lhs: _Money<C>) -> _Money<C> {
        return lhs
    }
    
    public static func ==(lhs: _Money<C>, rhs: _Money<C>) -> Bool {
        return lhs.decimal == rhs.decimal
    }
    
    public static func <(lhs: _Money<C>, rhs: _Money<C>) -> Bool {
        return lhs.decimal < lhs.decimal
    }
    
    /// Returns a Boolean value indicating whether the value of the first
    /// argument is less than or equal to that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func <=(lhs: _Money<C>, rhs: _Money<C>) -> Bool {
        return lhs.decimal <= lhs.decimal
    }
    
    /// Returns a Boolean value indicating whether the value of the first
    /// argument is greater than or equal to that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func >=(lhs: _Money<C>, rhs: _Money<C>) -> Bool {
        return lhs.decimal >= lhs.decimal
    }
    
    /// Returns a Boolean value indicating whether the value of the first
    /// argument is greater than that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func >(lhs: _Money<C>, rhs: _Money<C>) -> Bool {
        return lhs.decimal > lhs.decimal
    }
        
    public typealias DecimalNumberBehavior = C
    public typealias Currency = C

    public var magnitude: _Decimal<C>

    /// Access the underlying decimal.
    /// - returns: the `_Decimal<C>`
    public let decimal: _Decimal<C>

    /// Access the underlying minor units
    /// - returns: the `IntegerLiteralType` minor units
    public var minorUnits: IntegerLiteralType {
        return decimal.multiply(byPowerOf10: Currency.scale).intValue
    }

    /// Access the underlying decimal storage.
    /// - returns: the `_Decimal<C>.DecimalStorageType`
    public var storage: _Decimal<C>.DecimalStorageType {
        return decimal.storage
    }

    /// Flag to indicate if the decimal number is less than zero
    public var isNegative: Bool {
        return decimal.isNegative
    }

    /// The negative of Self.
    /// - returns: a `_Money<C>`
    public var negative: _Money {
        return _Money(decimal.negative)
    }

    /**
     Initialize a new value using an underlying decimal.

     - parameter value: a `_Decimal<C>` defaults to zero.
     */
    public init(_ value: _Decimal<C> = _Decimal<C>()) {
        decimal = value
        magnitude  = value.isNegative ? value.negative : value
    }

    /**
     Initialize the money with a integer representing minor units.

     - parameter minorUnits: a `IntegerLiteralType`
     */
    public init(minorUnits: IntegerLiteralType) {
        decimal = _Decimal<DecimalNumberBehavior>(integerLiteral: minorUnits).multiply(byPowerOf10: Currency.scale * -1)
        magnitude  = decimal.isNegative ? decimal.negative : decimal
    }

    /**
     Initialize a new value using the underlying decimal storage.
     At the moment, this is a `NSDecimalNumber`.

     - parameter storage: a `_Decimal<C>.DecimalStorageType`
     */
    public init(storage: _Decimal<C>.DecimalStorageType) {
        decimal = _Decimal<DecimalNumberBehavior>(storage: storage)
        magnitude  = decimal.isNegative ? decimal.negative : decimal
    }

    /**
     Initialize a new value using a `IntegerLiteralType`

     - parameter integerLiteral: a `IntegerLiteralType` for the system, probably `Int`.
     */
    public init(integerLiteral value: IntegerLiteralType) {
        decimal = _Decimal<DecimalNumberBehavior>(integerLiteral: value)
        magnitude  = decimal.isNegative ? decimal.negative : decimal
    }

    /**
     Initialize a new value using a `FloatLiteralType`

     - parameter floatLiteral: a `FloatLiteralType` for the system, probably `Double`.
     */
    public init(floatLiteral value: FloatLiteralType) {
        decimal = _Decimal<DecimalNumberBehavior>(floatLiteral: value)
        magnitude  = decimal.isNegative ? decimal.negative : decimal
    }
    
    /**
     Subtract a matching `_Money<C>` from the receiver.

     - parameter other: another instance of this type.
     - returns: another instance of this type.
     */
    public func subtract(other: _Money) -> _Money {
        return _Money(decimal.subtract(other.decimal))
    }

    /**
     Add a matching `_Money<C>` from the receiver.

     - parameter other: another instance of this type.
     - returns: another instance of this type.
     */
    public func add(other: _Money) -> _Money {
        return _Money(decimal.add(other.decimal))
    }

    /**
     Multiply a matching `_Money<C>` from the receiver.

     - parameter other: another instance of this type.
     - returns: another instance of this type.
     */
    public func multiplyBy(other: _Money) -> _Money {
        return _Money(decimal.multiply(by: other.decimal))
    }

    /**
     Divide a matching `_Money<C>` from the receiver.

     - parameter other: another instance of this type.
     - returns: another instance of this type.
     */
    public func divideBy(other: _Money) -> _Money {
        return _Money(decimal.divide(by: other.decimal))
    }

    /**
     The remainder of dividing another `_Money<C>` into the receiver.

     - parameter other: another instance of this type.
     - returns: another instance of this type.
     */
    public func remainder(other: _Money) -> _Money {
        return _Money(decimal.remainder(of: other.decimal))
    }
}

// MARK: - Equality

public func ==<C>(lhs: _Money<C>, rhs: _Money<C>) -> Bool {
    return lhs.decimal == rhs.decimal
}

// MARK: - Comparable

public func <<C>(lhs: _Money<C>, rhs: _Money<C>) -> Bool {
    return lhs.decimal < rhs.decimal
}

// MARK: - CustomStringConvertible

extension _Money: CustomStringConvertible {

    /**
     Returns the result of the `formatted` function using
     NSNumberFormatterStyle.CurrencyStyle.
    */
    public var description: String {
        return formatted(withStyle: C.defaultFormattingStyle)
    }
}

// MARK: - Value Coding

extension _Money: ValueCoding {
    public typealias Coder = _MoneyCoder<C>
}

/**
 Coding class to support `_Decimal` `ValueCoding` conformance.
 */
public final class _MoneyCoder<C: CurrencyType>: NSObject, NSCoding, CodedValue, CodingProtocol {

    public let value: _Money<C>

    public required init(_ v: _Money<C>) {
        value = v
    }

    public init?(coder aDecoder: NSCoder) {
        let decimal = _Decimal<C>.decode(aDecoder.decodeObject(forKey: "decimal") as AnyObject?)
        value = _Money<C>(decimal!)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(value.decimal.encoded, forKey: "decimal")
    }
}


// MARK: - Consumption Types

/// The current locale money
//public typealias Money = _Money<Currency.Local>
public typealias Money = _Money<Currency.RUB>
