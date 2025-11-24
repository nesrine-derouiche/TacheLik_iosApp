//
//  TeacherLessonAccess.swift
//  projectDAM
//
//  Created on 11/24/2025.
//

import Foundation

enum TeacherCourseContentAccess: String, Codable {
    case publicCourse = "public"
    case privateCourse = "private"
    
    var endpointSegment: String { rawValue }
    var requiresOwnership: Bool { self == .privateCourse }
    var blogSegment: String { rawValue }
}

extension TeacherCourse {
    var defaultLessonAccess: TeacherCourseContentAccess {
        if let price, price > 0 {
            return .privateCourse
        }
        return .publicCourse
    }
}
