// Copyright © 2016-2017 Shawn Baker using the MIT License.
import Foundation
import UIKit

extension String
{
    //**********************************************************************
    // length
    //**********************************************************************
    var length: Int
    {
        return self.count
    }
    
    //**********************************************************************
    // local
    //**********************************************************************
    var local: String
    {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    //**********************************************************************
    // htmlAttr
    //**********************************************************************
    var htmlAttr: NSAttributedString?
    {
        let text = NSString(format:"<span style=\"font-family: Helvetica; font-size: 17\">%@</span>", self) as String
        guard let data = text.data(using: String.Encoding.utf16, allowLossyConversion: false) else { return nil }
		//let attr = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]
		guard let html = try? NSMutableAttributedString(data: data,
								  options: [.documentType : NSAttributedString.DocumentType.html],
								  documentAttributes: nil) else { return nil }
        //guard let html = try? NSMutableAttributedString(data: data, options: attr, documentAttributes: nil) else { return nil }
        return html
    }
    
    //**********************************************************************
    // subscript integerIndex
    //**********************************************************************
    subscript(integerIndex: Int) -> Character
    {
        let i = index(startIndex, offsetBy: integerIndex)
        return self[i]
    }
    
    //**********************************************************************
    // subscript integerRange
    //**********************************************************************
    subscript(integerRange: Range<Int>) -> String
    {
        let start = index(startIndex, offsetBy: integerRange.lowerBound)
        let end = index(startIndex, offsetBy: integerRange.upperBound)
        return String(self[start..<end])
    }
}
