//
//  parser.swift
//

// Pratt parser (enhanced recursive descent parser that supports operator fixity and associativity)

// TO DO: how best to implement incremental parsing e.g. might do per-line parsing, with each Line keeping a count of any opening/closing { }, [ ], ( ), « » blocks and quotes, along with any other hints such as indentation and possible keywords; a block-level analyzer could then attempt to collate lines into balanced blocks, detecting both obvious imbalances (e.g. `{[}]`, `{[[]}`) and more subtle ones (e.g. `{[]{[]}`) and providing best guesses as to where the correction should be made (e.g. given equally indented blocks, `{}{{}{}` the unbalanced `{` is more likely to need the missing `}` inserted before the next `{}`, not at end of script [as a dumber parser would report]; looking for keywords that are commonly expected at top-level or within blocks may also provide hints as to when to discard previous tally as unbalanced and start a new one from top level)

import Foundation



class Parser {
    
    
    func parseExpression(_ precedence: Int) throws -> Value {
        // TO DO
        return noValue
    }
    
}
