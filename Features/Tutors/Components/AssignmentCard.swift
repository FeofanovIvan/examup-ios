import SwiftUI

struct AssignmentCard: View {
    let assignment: TutorAssignment

    var body: some View {
        PlaceholderBlock(title: assignment.title, subtitle: assignment.subject.title)
    }
}
