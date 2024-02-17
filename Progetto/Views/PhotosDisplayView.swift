//
//  PhotosDisplayView.swift
//  Progetto
//
//  Created by Lorenzo Bazzana on 31/01/24.
//

import SwiftUI
import Photos
import PhotosUI

struct PhotosDisplayView: View {
    
    @State var pickedPhotos : [PhotosPickerItem] = []
    var oldPickedPhotos: [PhotosPickerItem] = []
    @State var editing: Bool = false
    var pickerConfig = PHPickerConfiguration()
    @Binding var IDPhotos: [IdentifiableImage]
    @State var selectedPhotos = Dictionary<UUID, Bool>()
    
    let grid: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    @State var itemToShow: IdentifiableImage? = nil
    
    func selectAll(){
        for photo in IDPhotos{
            selectedPhotos[photo.id] = true
        }
    }
    
    func removeSelected(){
        var indicesToRemove: [Int] = []
        for idx in IDPhotos.indices {
            if selectedPhotos[IDPhotos[idx].id] != nil{
                indicesToRemove.append(idx)
            }
        }
        IDPhotos.remove(atOffsets: IndexSet(indicesToRemove))
        pickedPhotos.remove(atOffsets: IndexSet(indicesToRemove))
        
    }

    
    var body: some View {
        
        VStack(alignment: .leading){
            HStack(alignment: .firstTextBaseline){
                Text("Selected photos")
                    .font(.title)
                .bold()
                Spacer()
                if(editing){
                    Button("Cancel"){
                        editing = false
                        selectedPhotos.removeAll()
                    }.padding(.trailing)
                }
                else{
                    Button("Edit"){
                        editing = true
                    }
                    .padding(.trailing)
                }
                
            }
            .padding()
                ScrollView {
                    LazyVGrid(columns: grid){
                        ForEach(IDPhotos){photo in
                            GeometryReader{geometry in
                                let img = UIImage(data:photo.data as Data)
                                ThumbnailImage(img: img!, thumbnailSize: 50, width: geometry.size.width, heigth: geometry.size.width, editing: editing, isSelected: selectedPhotos[photo.id] ?? false)
                                    .onTapGesture {
                                        if (!editing){
                                            itemToShow = photo
                                        } else{
                                            if selectedPhotos[photo.id] == nil{
                                                selectedPhotos[photo.id] = true
                                            } else{
                                                selectedPhotos.removeValue(forKey: photo.id)
                                            }
                                        }
                                    }.fullScreenCover(item: $itemToShow){ image in
                                        FullImageView(img: image, show:$itemToShow)
                                    }
                            }
                            .aspectRatio(1, contentMode: .fill)
                        }
                    }
                    .padding()
                }
            Spacer()
            
            if(editing){
                HStack{
                    PhotosPicker(selection: $pickedPhotos,
                                 matching: .images) {
                        Text("Add")
                    }
                    Spacer()
                    Button(action:{removeSelected()}){
                        Text("Remove")
                    }
                    .foregroundColor(.red)
                    Spacer()
                    Button(action: {selectAll()}){
                        Text("Select all")
                    }
                }
                .padding(.horizontal)
            }
            Text("Selected \(IDPhotos.count) photo" + (IDPhotos.count == 1 ? "" : "s"))
                .padding()
            
        }.task(id: pickedPhotos){
            editing = false
            for photo in pickedPhotos{
                if let extractedImage = try? await photo.loadTransferable(type: Data.self){
                    let imageToAppend = IdentifiableImage(rawData: extractedImage as NSData)
                    if !(IDPhotos.contains(imageToAppend)){
                        IDPhotos.append(imageToAppend)
                    }
                }
            }
        }
    }
}
