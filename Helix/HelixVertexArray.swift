//
//  HelixVertexArray.swift
//  Normals
//
//  Created by Morgan Wilde on 10/01/2015.
//  Copyright (c) 2015 Morgan Wilde. All rights reserved.
//

import Foundation
import SceneKit

class HelixVertexArray {
    // Helix appearance
    var circles                 = 40   // how many circles to stitch
    var circleSegments          = 4     // each circle is made up of # of points
    var circleRadius: Float     = 1     // how thick the helix is
    var pitchInherent: Float    = 0.75     // the greater the number, the further each rung is
    var pitchCurrent: Float     = 1
    var helixRadius: Float
    
    var width: GLfloat      // x
    var height: GLfloat     // y
    var depth: GLfloat      // z
    
    var vertexArray: VertexArray
    var normalArray: [Float3] = []
    var elementArray: [CInt] = []
    
    var vertexSource: SCNGeometrySource
    var normalSource: SCNGeometrySource
    var element: SCNGeometryElement
    var geometry: SCNGeometry
    
    var quality = true
    
    init(width: Float, height: Float, depth: Float, pitch: Float, quality: Bool) {
        
        if quality {
            circles = 70
            circleSegments = 8
        } else {
            circles = 40
            circleSegments = 4
        }
        
        self.width = width
        self.height = height
        self.depth = depth
        self.pitchCurrent = pitch
        self.helixRadius = self.width / 2
        
        // Initial position for the helix
        var x: Float
        var y: Float
        var z: Float
        var t = -height/pitchInherent/2
        let yIncrement: Float = (height * (1/pitchInherent)) / Float(circles)
        var helixAngle: Float = 0
        var circleNumber = 0
        
        // Vertex array
        vertexArray = VertexArray(width: circleSegments, height: circles)
        vertexArray.continuesInX = true
        
        for var i = 0; i < circles; i++ {
            x = helixRadius * cos(t)
            z = helixRadius * sin(t)
            y = pitchInherent * pitchCurrent * t
            t += yIncrement
            
            helixAngle = atan2(x, z)
            
            let circleCenter = Float3(x: x, y: y, z: z)
            
            let angleZenith: Float =  0 * Float(M_PI) / 180
            let angleInitial: Float = 90
            let angleAzimuth: Float = helixAngle + angleInitial * Float(M_PI) / 180
            
            let n = Float3(
                x: cos(angleZenith) * sin(angleAzimuth),
                y: sin(angleAzimuth) * sin(angleZenith),
                z: cos(angleAzimuth))
            let u = Float3(
                x: -sin(angleZenith),
                y: cos(angleZenith),
                z: 0)
            let nxu = Float3(
                x: cos(angleAzimuth) * cos(angleZenith),
                y: cos(angleAzimuth) * sin(angleZenith),
                z: -sin(angleAzimuth))
            
            var circleSegment: Float = 0
            for var j = 0; j < circleSegments; j++ {
                let circleX: Float = circleRadius * cos(circleSegment)
                let circleY: Float = circleRadius * sin(circleSegment)
                
                let circleCoordinates = Float3(x: circleX, y: circleY, z: 0)
                
                let part1 = u.factor(circleCoordinates.x)
                let part2 = nxu.factor(circleCoordinates.y)
                
                let circleParameter = part1.add(part2).add(circleCenter)
                
                vertexArray.setVertex(circleParameter, x: j, y: circleNumber)
                circleSegment += Float(2*M_PI) / Float(circleSegments)
            }
            circleNumber++
        }
        
        // Element array
        // Goes level by level stiching them together with triangles
        for var v = 0; v < vertexArray.height - 1; v++ {
            for var h = 0; h < vertexArray.width; h++ {
                let pointTopCoordinate = (h, v)
                let pointBottomCoordinate = (h, v + 1)
                // Top
                let pointTop = vertexArray.getVertexIndexCInt(pointTopCoordinate.0, pointTopCoordinate.1)
                let pointTopRight = vertexArray.getAdjacentVertexIndexCInt(pointTopCoordinate.0, y: pointTopCoordinate.1, from: .East)
                // Bottom
                let pointBottom = vertexArray.getVertexIndexCInt(pointBottomCoordinate.0, pointBottomCoordinate.1)
                let pointBottomRight = vertexArray.getAdjacentVertexIndexCInt(pointBottomCoordinate.0, y: pointBottomCoordinate.1, from: .East)
                
                elementArray += [pointTop, pointTopRight, pointBottom]
                elementArray += [pointBottom, pointTopRight, pointBottomRight]
            }
        }
        
        // Normal array
        for var v = 0; v < vertexArray.height; v++ {
            for var h = 0; h < vertexArray.width; h++ {
                normalArray += [vertexArray.getNormal(h, y: v)]
            }
        }
        
        // Create the vertex source
        let vertexData = NSData(bytes: vertexArray.array, length: vertexArray.array.count * sizeof(Float3))
        vertexSource = SCNGeometrySource(
            data: vertexData,
            semantic: SCNGeometrySourceSemanticVertex,
            vectorCount: vertexArray.array.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(GLfloat),
            dataOffset: 0,
            dataStride: sizeof(Float3))
        
        // Create the normal source
        let normalData = NSData(bytes: normalArray, length: normalArray.count * sizeof(Float3))
        normalSource = SCNGeometrySource(
            data: normalData,
            semantic: SCNGeometrySourceSemanticNormal,
            vectorCount: normalArray.count,
            floatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: sizeof(GLfloat),
            dataOffset: 0,
            dataStride: sizeof(Float3))
        
        // Create the only element for this geometry
        let elementData = NSData(bytes: elementArray, length: elementArray.count * sizeof(CInt))
        element = SCNGeometryElement(
            data: elementData,
            primitiveType: .Triangles,
            primitiveCount: elementArray.count / 3,
            bytesPerIndex: sizeof(CInt))
        
        // Create the geometry itself
        geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
        geometry.firstMaterial?.doubleSided = true
    }
    
    func getNode() -> SCNNode {
        return SCNNode(geometry: geometry)
    }
}