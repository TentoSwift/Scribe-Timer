//
//  Heart.swift
//  Timer
//
//  Created by 石野天斗 on 2026/02/10.
//

import SwiftUI

struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        return Path { p in
            // 下の尖り
            p.move(to: CGPoint(x: x + 0.50*w, y: y + 0.95*h))

            // 左下 → 左上のふくらみ（キュービックで滑らかに）
            p.addCurve(
                to: CGPoint(x: x + 0.05*w, y: y + 0.35*h),
                control1: CGPoint(x: x + 0.20*w, y: y + 0.85*h),
                control2: CGPoint(x: x + 0.00*w, y: y + 0.60*h)
            )

            // 左上の丸 → 上のくぼみ
            p.addCurve(
                to: CGPoint(x: x + 0.50*w, y: y + 0.20*h),
                control1: CGPoint(x: x + 0.10*w, y: y + 0.10*h),
                control2: CGPoint(x: x + 0.35*w, y: y + 0.00*h)
            )

            // 上のくぼみ → 右上の丸
            p.addCurve(
                to: CGPoint(x: x + 0.95*w, y: y + 0.35*h),
                control1: CGPoint(x: x + 0.65*w, y: y + 0.00*h),
                control2: CGPoint(x: x + 0.90*w, y: y + 0.10*h)
            )

            // 右上 → 右下 → 下の尖り
            p.addCurve(
                to: CGPoint(x: x + 0.50*w, y: y + 0.95*h),
                control1: CGPoint(x: x + 1.00*w, y: y + 0.60*h),
                control2: CGPoint(x: x + 0.80*w, y: y + 0.85*h)
            )

            p.closeSubpath()
        }
    }
}

struct Triangle: Shape {
    var cornerRadius: CGFloat = 20
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 三角形の3つの頂点を定義
        let points = [
            CGPoint(x: rect.midX, y: rect.minY), // 上
            CGPoint(x: rect.maxX, y: rect.maxY), // 右下
            CGPoint(x: rect.minX, y: rect.maxY)  // 左下
        ]
        
        // 描画開始位置を最後の点にセット
        path.move(to: points.last!)
        
        // 各頂点に対して、次の点との間に接円（丸み）を描く
        for i in 0..<points.count {
            let nextIndex = (i + 1) % points.count
            let nextNextIndex = (i + 2) % points.count
            
            path.addArc(tangent1End: points[i],
                        tangent2End: points[nextIndex],
                        radius: cornerRadius)
        }
        
        path.closeSubpath()
        return path
    }
}



struct Star: Shape {
    // 星の角の数
    var corners: Int = 5
    // 星の太さ（0.3〜0.7くらいが実用的）
    var smoothness: CGFloat = 0.45
    // 角の丸み半径（0だと尖ります。サイズに合わせて調整が必要です）
    var cornerRadius: CGFloat = 7
    
    func path(in rect: CGRect) -> Path {
        guard corners >= 2 else { return Path() }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        // 枠に収まるように半径を計算
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness
        
        let angleAdjustment = .pi * 2 / Double(corners * 2)
        var currentAngle = -CGFloat.pi / 2 // 真上からスタート
        
        // 1. すべての頂点座標を先に計算して配列に格納
        var points: [CGPoint] = []
        for corner in 0..<corners * 2 {
            let radius = (corner % 2 == 0) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(currentAngle) * radius,
                y: center.y + sin(currentAngle) * radius
            )
            points.append(point)
            currentAngle += angleAdjustment
        }
        
        // 2. パスを描画
        var path = Path()
        guard let firstPoint = points.first else { return path }
        
        // addArcを正しく機能させるため、最後の点からスタートします
        path.move(to: points.last!)
        
        // 各頂点について、次の点とその次の点を参照して角を丸める
        for i in 0..<points.count {
            let nextPoint = points[i]
            // (i + 1) % points.count で配列の最後を超えたら最初に戻るようにする
            let pointAfterNext = points[(i + 1) % points.count]
            
            // 現在位置から nextPoint に向かって線を引き、
            // nextPoint と pointAfterNext を結ぶ線に接する円弧を描く
            path.addArc(tangent1End: nextPoint,
                        tangent2End: pointAfterNext,
                        radius: cornerRadius)
        }
        
        path.closeSubpath()
        return path
    }
}


struct ScribbleWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // 1. スタート地点
        path.move(to: CGPoint(x: w * 0.08, y: h * 0.62))
        
        // 2. 最初の山（ここを直角に近く鋭く、上がりを直線的に）
        // 制御点をライン上に寄せることで、直線を引いたような勢いを出します
        path.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.08),
                      control1: CGPoint(x: w * 0.25, y: h * 0.45), // 直線的な上がり
                      control2: CGPoint(x: w * 0.38, y: h * 0.05)) // 頂点直前でクイッと曲げる
        
        // 3. 谷（深すぎず、少し右に流れるように）
        path.addCurve(to: CGPoint(x: w * 0.65, y: h * 0.82),
                      control1: CGPoint(x: w * 0.48, y: h * 0.15), // 頂点からの鋭い下り
                      control2: CGPoint(x: w * 0.55, y: h * 0.82)) // 谷底へのアプローチ
        
        // 4. 二つ目の山（ここは丸く、お団子のようなカーブに）
        path.addCurve(to: CGPoint(x: w * 0.90, y: h * 0.48),
                      control1: CGPoint(x: w * 0.75, y: h * 0.82), // 谷からの立ち上がり
                      control2: CGPoint(x: w * 0.82, y: h * 0.35)) // ふっくらさせる
        
        // 5. 最後の止め（少し内側に入って終わる）
        path.addCurve(to: CGPoint(x: w * 0.96, y: h * 0.72),
                      control1: CGPoint(x: w * 0.95, y: h * 0.55),
                      control2: CGPoint(x: w * 0.97, y: h * 0.65))
        
        return path
    }
}
