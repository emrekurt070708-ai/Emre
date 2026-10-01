# Rampa duvari olusturucu
# Kullanim: duvarin gececegi cizgiyi (edge) sec, bu kodun tamamini
# Pencere > Ruby Konsolu (Window > Ruby Console) icine yapistir, Enter'a bas.
# Secili cizgi boyunca, rampanin egimini takip eden DIKEY bir duvar yapar.
# Tek Ctrl+Z ile geri alinir.

rampa_duvari = lambda do
  yukseklik = 100.cm # duvar yuksekligi
  kalinlik  = 20.cm  # duvar kalinligi
  hiza      = 0      # 0 = cizgi duvarin ortasinda, 1 = duvar cizginin bir yaninda, -1 = diger yaninda

  model = Sketchup.active_model
  edges = model.selection.grep(Sketchup::Edge)
  if edges.empty?
    UI.messagebox('Once duvarin gececegi cizgiyi (edge) sec.')
    return
  end
  ebeveyn = edges.first.parent
  edges = edges.select { |e| e.parent == ebeveyn }
  ents = ebeveyn.entities
  h = yukseklik.to_f
  t = kalinlik.to_f

  # Edge'leri uc uca siralayip zincirlere ayir
  zincirler = []
  kalan = edges.dup
  until kalan.empty?
    derece = Hash.new(0)
    kalan.each { |e| e.vertices.each { |v| derece[v] += 1 } }
    bas_e = kalan.find { |e| e.vertices.any? { |v| derece[v] == 1 } } || kalan.first
    bas_v = bas_e.vertices.find { |v| derece[v] == 1 } || bas_e.start
    verts = [bas_v]
    e = bas_e
    v = bas_v
    while e
      kalan.delete(e)
      v = e.other_vertex(v)
      verts << v
      e = kalan.find { |x| x.vertices.include?(v) }
    end
    kapali = verts.size > 3 && verts.last == verts.first
    verts.pop if kapali
    noktalar = verts.map { |vv| p = vv.position; [p.x.to_f, p.y.to_f, p.z.to_f] }
    zincirler << [noktalar, kapali]
  end

  duvar = lambda do |pts, kapali|
    # Yatayda ust uste dusen noktalari (dikey edge'leri) at
    temiz = [pts.first]
    pts.drop(1).each do |q|
      temiz << q if Math.hypot(q[0] - temiz.last[0], q[1] - temiz.last[1]) > 0.01
    end
    if kapali && temiz.size > 1 &&
       Math.hypot(temiz.last[0] - temiz.first[0], temiz.last[1] - temiz.first[1]) <= 0.01
      temiz.pop
    end
    n = temiz.size
    return nil if n < 2 || (kapali && n < 3)

    seg = kapali ? n : n - 1
    yonler = (0...seg).map do |i|
      a = temiz[i]
      b = temiz[(i + 1) % n]
      dx = b[0] - a[0]
      dy = b[1] - a[1]
      l = Math.hypot(dx, dy)
      [dx / l, dy / l]
    end
    normaller = yonler.map { |d| [-d[1], d[0]] }

    # Koselerde gonye (miter) icin kaydirma vektoru
    gonye = lambda do |a, b|
      sx = a[0] + b[0]
      sy = a[1] + b[1]
      l = Math.hypot(sx, sy)
      return b if l < 1e-9
      mx = sx / l
      my = sy / l
      c = [mx * b[0] + my * b[1], 0.2].max
      [mx / c, my / c]
    end
    kaydir = (0...n).map do |k|
      if !kapali && k.zero? then normaller[0]
      elsif !kapali && k == n - 1 then normaller[seg - 1]
      else gonye.call(normaller[(k - 1) % seg], normaller[k % seg])
      end
    end

    fa = t * (hiza + 1) / 2.0
    fb = t * (hiza - 1) / 2.0
    a_pts = temiz.each_with_index.map { |p, k| [p[0] + kaydir[k][0] * fa, p[1] + kaydir[k][1] * fa, p[2]] }
    b_pts = temiz.each_with_index.map { |p, k| [p[0] + kaydir[k][0] * fb, p[1] + kaydir[k][1] * fb, p[2]] }
    ust = lambda { |c| [c[0], c[1], c[2] + h] }

    grup = ents.add_group
    grup.name = 'Rampa Duvari'
    ge = grup.entities

    # Yuz ekle; duz degilse iki ucgene bol. Normali disari cevir.
    yuz = lambda do |q, disari|
      q = q.map { |c| Geom::Point3d.new(*c) }
      f = (ge.add_face(q) rescue nil)
      fs = f ? [f] : [(ge.add_face(q[0], q[1], q[2]) rescue nil), (ge.add_face(q[0], q[2], q[3]) rescue nil)]
      fs.compact.each { |yy| yy.reverse! if yy.normal.dot(Geom::Vector3d.new(*disari)) < 0 }
    end

    seg.times do |i|
      j = (i + 1) % n
      nx, ny = normaller[i]
      yuz.call([a_pts[i], a_pts[j], ust.call(a_pts[j]), ust.call(a_pts[i])], [nx, ny, 0])
      yuz.call([b_pts[i], ust.call(b_pts[i]), ust.call(b_pts[j]), b_pts[j]], [-nx, -ny, 0])
      yuz.call([a_pts[i], b_pts[i], b_pts[j], a_pts[j]], [0, 0, -1])
      yuz.call([ust.call(a_pts[i]), ust.call(a_pts[j]), ust.call(b_pts[j]), ust.call(b_pts[i])], [0, 0, 1])
    end
    unless kapali
      d0 = yonler.first
      d1 = yonler.last
      yuz.call([a_pts[0], ust.call(a_pts[0]), ust.call(b_pts[0]), b_pts[0]], [-d0[0], -d0[1], 0])
      yuz.call([a_pts[-1], b_pts[-1], ust.call(b_pts[-1]), ust.call(a_pts[-1])], [d1[0], d1[1], 0])
    end

    # Ayni duzlemdeki yuzler arasindaki cizgileri yumusat
    ge.grep(Sketchup::Edge).each do |ed|
      next unless ed.faces.size == 2
      next unless ed.faces[0].normal.dot(ed.faces[1].normal) > 0.9999
      ed.soft = true
      ed.smooth = true
    end
    grup
  end

  model.start_operation('Rampa Duvari', true)
  begin
    gruplar = zincirler.map { |pts, kapali| duvar.call(pts, kapali) }.compact
    model.commit_operation
  rescue StandardError => err
    model.abort_operation
    UI.messagebox("Duvar olusturulamadi: #{err.message}")
    return
  end
  model.selection.clear
  model.selection.add(gruplar)
  puts "#{gruplar.size} duvar olusturuldu. Kati (solid): #{gruplar.map(&:manifold?).inspect}"
end
rampa_duvari.call
