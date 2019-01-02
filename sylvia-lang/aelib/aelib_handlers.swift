//
//  aelib_handlers.swift
//

import Foundation


// need a `tell TARGET BLOCK` operator where BLOCK is evaled in a custom sub-scope containing command handlers, object specifier roots, and enums
/*
 
 
 tell app “Finder” {
 
    file_names: get (name of every document_file of folder named “Documents” of home)
 
 
    new_folder: make (new: folder, at: desktop, with_properties: [name: “text files”])
 
    duplicate (every file of desktop where name_extension eq “txt”, to: new_folder)
 
 
 }
 
 */
