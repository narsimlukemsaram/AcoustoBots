import numpy as np


def coords_shape(sidelengths, resolution, lam):

    """
    
    reshapes a propagation with the correct dimensions and in the correct plane.
    
    args:
        sidelengths: distances which the propagation plane extends in the form: [(-x, +x), (-y, +y), (-z, +z)].
        resolution: how many points will there be in the propagation plane for each point in the source plane?
        
    returns:
        shape_tuple: a tuple containing the 2D dimensions for the propagation to be reshaped to.
        
    
    """
    
    # ----> yz plane <----
    if sidelengths[0] == (0, 0):
        
        shape_tuple = (int(2*resolution*(sidelengths[2][0] + sidelengths[2][1])/lam),
                       int(2*resolution*(sidelengths[1][0] + sidelengths[1][1])/lam))
    
    # ----> xz plane <----
    elif sidelengths[1] == (0, 0):
        
        shape_tuple = (int(2*resolution*(sidelengths[2][0] + sidelengths[2][1])/lam),
                       int(2*resolution*(sidelengths[0][0] + sidelengths[0][1])/lam)) 
    
    # ----> xy plane <----
    elif sidelengths[2] == (0, 0):
        
        shape_tuple = (int(2*resolution*(sidelengths[1][0] + sidelengths[1][1])/lam),
                       int(2*resolution*(sidelengths[0][0] + sidelengths[0][1])/lam))
    
    return shape_tuple
    
    
def GF_propagator_function_builder(reflector_points, eval_points, normals, areas, k):
    
    """
    
    http://www.personal.reading.ac.uk/~sms03snc/fe_bem_notes_sncw.pdf
    
    builds a scattering matrix for the sound propagation of a set elements/sources that cover
    a finite area in which they are assumed to have a constant pressure.

    args:
        reflector_points: matrix of x,y,z coords for the reflecting elements.
        eval_points: matrix of evaluation x,y,z coords at the propagation plane.
        normals: for a flat metasurface you get n*m times the vector [0, 0, 1].
        area: vector of the areas covered by each element (1, n*m).
        k: wavenumber.
        

    returns:
        H: Gives distance matrix of all distances between reflector and evaluation points (n*m, p*q).
        
    """
    # assign variables for x, y and z coord vectors for reflectors, evaluation points and normals
    rp_x, rp_y, rp_z = reflector_points.T
    ep_x, ep_y, ep_z = eval_points.T
    nm_x, nm_y, nm_z = normals
    
    # compute distances between eval_points and reflecting elements
    r = np.sqrt((rp_x.reshape(-1, 1) - ep_x.reshape(1, -1))**2 + \
                (rp_y.reshape(-1, 1) - ep_y.reshape(1, -1))**2 + \
                (rp_z.reshape(-1, 1) - ep_z.reshape(1, -1))**2)
    
    # partial of greens w.r.t normals
    g = -(1/(4*np.pi)) * np.exp(1j*k*r) * (1j*k*r-1)/(r**3)
    
    # find infinities and set them to zero.
    g[g == np.inf] = 0 
    
    # equation 2.21 in the pdf
    g = g * ((ep_x.reshape(1, -1) - rp_x.reshape(-1, 1)) * nm_x.T + \
             (ep_y.reshape(1, -1) - rp_y.reshape(-1, 1)) * nm_y.T + \
             (ep_z.reshape(1, -1) - rp_z.reshape(-1, 1)) * nm_z.T)
    
    # include reflector areas to build propagator function H
    H = g * areas.T
    
    return H


def points_vector_builder(centrepoint, extents, pixel_spacing):
    
    """
    
    We can define an evalution plane using 3 inputs:

    args:
        centrepoint: (x, y, z) tuple describing the central point of the evaulation plane (meters).
        extents: list of tuples in the form [(+x, -x), (+y, -y), (+z, -z)] describing the distances which the plane
        extends in each +ve and -ve direction from the centrepoint. In order to create a valid 2D plane, one of
        (+x, -x), (+y, -y), or (+z, -z) must be (0, 0).
        pixel_spacing: distance between pixels on the evaluation plane (meters).
    
    returns:
        points_vector_list: list of x, y and z coordinate arrays.
    
    """

    # side vectors for evaluation point matrix
    x = np.arange(centrepoint[0] - (extents[0][0]) + (pixel_spacing/2),
                  centrepoint[0] + (extents[0][1]),
                  pixel_spacing)
    
    y = np.arange(centrepoint[1] - (extents[1][0]) + (pixel_spacing/2),
                  centrepoint[1] + (extents[1][1]),
                  pixel_spacing)
    
    z = np.arange(centrepoint[2] - (extents[2][0]) + (pixel_spacing/2),
                  centrepoint[2] + (extents[2][1]),
                  pixel_spacing)
    
    # if yz plane
    if extents[0] == (0, 0): 
        yy, zz = np.meshgrid(y, z)
        xx = centrepoint[0]*np.ones(len(y)*len(z))
    
    # if xz plane
    elif extents[1] == (0, 0): 
        xx, zz = np.meshgrid(x, z)
        yy = centrepoint[1]*np.ones(len(x)*len(z))
        
    # if xy plane    
    elif extents[2] == (0, 0):
        xx, yy = np.meshgrid(x, y)
        zz = centrepoint[2]*np.ones(len(x)*len(y))
    
    # return a list of x, y and z vectors
    
    return np.concatenate((xx.reshape(1, -1), yy.reshape(1, -1), zz.reshape(1, -1))).T
    
    
def PM_propagator_function_builder(eval_points, tran_points, tran_normal, k, p0=3.4, d=9/1000):
    
    """ 
    Piston model calculator. Finds the complex pressure propagated by transducers from
    one plane to another, determined using the PM_pesb function. (see GS-PAT eq.2).
    
    args:
        eval_points = numpy array of xyz points in the evaluation field.
        tran_points = numpy array of xyz points in the transducer field.
        tran_normal = normal vector for transducers (assumed to be constant for all transducers)
        k = wavenumber [waves/sec]
        p0 = (3.4 [Pa]) reference pressure for Murata transducer measured at a distance of 1m assuming a driving voltage of 20V.
        d = (9/1000 [m]) diameter of transducer.
        
    returns:
    """
    
    # matrix of vector distances between tran and eval points
    tp = np.array([eval_point - tran_point for tran_point in tran_points for eval_point in eval_points])
    
    # find cross and dot product of each t -> p vector and the transducer normal
    cross_product = np.cross(tp, tran_normal)
    dot_product = np.linalg.norm(tp, axis=1)*np.linalg.norm(tran_normal, axis=0)
    
    # find sin theta of the angle
    sin_theta = np.linalg.norm(cross_product, axis=1)/dot_product
    
    # argument of 1st order Bessel function
    J_arg = k*(d/2)*sin_theta
    
    # taylor expansion of first order Bessel function over its agrument (J_1(J_arg)/J_arg)
    tay = (1/2)-(J_arg**2/16)+(J_arg**4/384)-(J_arg**6/18432)+(J_arg**8/1474560)-(J_arg**10/176947200)
    
    # build directivity function
    H = 2*p0*(tay/np.linalg.norm(tp, axis=1))*np.exp(1j*k*np.linalg.norm(tp, axis=1))
    
    return H
    
    
def target_builder_char(char, font_file, fontsize, im_w, im_h, slice_threshold = 0.05):
    
    """
    
    Creates an array of numpy array images to be used as targets with the iterative GS function.
    
    args:
        char: character to be made into target.
        font_file: .tff file containing the character font.
        fontsize: font size (in pts, knowing that 10pts = 13px).
        im_h: height of the numpy array in pixels, the function assumes a square array.
        slice_threshold :  sum values in row or column and delete them if below this threshold
    returns:
        target_images: array of target images.
        
    """
    
    from PIL import Image, ImageDraw, ImageFont 
    bg_color = (255, 255, 255) # Image background color (white)
    
    fnt = ImageFont.truetype(font_file, fontsize) # Create font object
    w, h = fnt.getsize(str(char))
    im = Image.new('RGB', (w, h), color = bg_color)
    draw = ImageDraw.Draw(im)
    draw.text((0, 0), str(char), font=fnt, fill="black")

    target_image = np.array(im)[:,:,:1]
    target_image = np.reshape(target_image[:,:],(target_image.shape[0], target_image.shape[1]))
    target_image = 1 - target_image/255 # normalise

    # remove rows < threshold
    x_del = []
    for i, x in enumerate(np.sum(target_image, axis=1)):
        if x < slice_threshold:
            x_del.append(i)
    target_image = np.delete(target_image, x_del, axis=0)

    # remove columns < threshold
    y_del = []
    for j, y in enumerate(np.sum(target_image, axis=0)):
        if y < slice_threshold:
            y_del.append(j)
    target_image = np.delete(target_image, y_del, axis=1)

    # pad zeros around the characters
    target_dummy = target_image
    w, h = target_dummy.shape[0], target_dummy.shape[1]
    target_image = np.zeros((im_w, im_h))    
    target_image[int((im_w-w)/2): int((im_w+w)/2), int((im_h-h)/2):int((im_h+h)/2)] = target_dummy   
    
    return target_image