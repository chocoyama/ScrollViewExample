//
//  ContentView.swift
//  ScrollViewSynchronize
//
//  Created by Takuya Yokoyama on 2019/11/23.
//  Copyright © 2019 chocoyama. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var index = 0
    
    var body: some View {
        VStack {
            SwiftUIPagerView(index: $index, pages: (0..<30).map { Page(page: $0) })
                .background(Color.blue)
            MenuView(index: $index, pages: 30)
                .background(Color.yellow)
            HStack {
                Button(action: { self.index -= 1 }) {
                    Text("-")
                }
                Button(action: { self.index += 1 }) {
                    Text("+")
                }
            }
        }
    }
}

struct OffsetScrollView: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { (geometry: GeometryProxy) in
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 0) {
                        GeometryReader { (geometry2: GeometryProxy) -> Text in
                            let newOffset = geometry2.frame(in: .global).minX
                            if self.offset != newOffset {
                                self.offset = newOffset
                            }
                            return Text("")
                        }
                        ForEach(0..<100) { page in
                            Text("\(page)")
                                .frame(width: 50)
                        }
                    }
                }
                
                Text("\(self.offset)")
                    .frame(height: 50)
            }
        }
    }
}

var offsets: [Int: CGFloat] = [:]

struct MenuView: View {
    @Binding var index: Int
    let pages: Int
    @State private var offset: CGFloat = 0
    private var currentOffset: CGFloat { offsets[index] ?? 0.0 }
    private var isVisibleIndex: Bool { currentOffset < UIScreen.main.bounds.width }
    
    var body: some View {
        GeometryReader { parentGeometry in
            self.scrollView
        }.frame(width: UIScreen.main.bounds.width, height: 50)
    }
    
    var scrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 16) {
                ForEach(0..<pages) { page in
                    GeometryReader { geometry in
                        Text("\(page)")
                            .foregroundColor(self.index == page ? Color.red : Color.black)
                            .fixedSize()
                            .frame(width: geometry.size.width)
                            .onTapGesture { self.index = page }
                            .onAppear {
                                offsets[page] = geometry.frame(in: .global).minX
                                print("### global", geometry.frame(in: .global).minX)
                        }
                    }
                }.offset(x: isVisibleIndex ? 0 : -currentOffset)
            }
        }
        .onAppear { offsets = [:] }
        .onDisappear { offsets = [:] }
        .onTapGesture {
            print("### isVisibleIndex", self.isVisibleIndex)
            print("### currentOffset", self.currentOffset)
        }
    }
}

struct Page: View, Identifiable {
    var id: Int { page }
    let page: Int
    
    var body: some View {
        Text("\(page)")
    }
}

struct SwiftUIPagerView<Content: View & Identifiable>: View {

    @Binding var index: Int
    @State private var offset: CGFloat = 0
    @State private var isGestureActive: Bool = false

    // 1
    var pages: [Content]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 0) {
                    ForEach(self.pages) { page in
                        page
                            .frame(width: geometry.size.width, height: nil)
                    }
                }
            }
            // 2
            .content.offset(x: self.isGestureActive ? self.offset : -geometry.size.width * CGFloat(self.index))
            // 3
            .frame(width: geometry.size.width, height: nil, alignment: .leading)
            .gesture(DragGesture().onChanged({ value in
                // 4
                self.isGestureActive = true
                // 5
                self.offset = value.translation.width + -geometry.size.width * CGFloat(self.index)
            }).onEnded({ value in
                if -value.predictedEndTranslation.width > geometry.size.width / 2, self.index < self.pages.endIndex - 1 {
                    self.index += 1
                }
                if value.predictedEndTranslation.width > geometry.size.width / 2, self.index > 0 {
                    self.index -= 1
                }
                // 6
                withAnimation { self.offset = -geometry.size.width * CGFloat(self.index) }
                // 7
                DispatchQueue.main.async { self.isGestureActive = false }
            }))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
