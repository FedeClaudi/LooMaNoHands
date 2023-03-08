using LookMaNoHands, GLMakie, Images
using GLMakie.GLFW
using GLMakie: to_native
using Term.Prompts


# TODO make the cropper work and save a bunch of Images
# TODO train face recognition model and get face location + fit oval?

mutable struct CropperRunner
    img_paths::Vector{String}
    idx::Int
end

function CropperRunner(folder)
    img_paths = filter(f -> !isdir(f), readdir(folder))
    CropperRunner(img_paths, 0)
end

function load_next(runner::CropperRunner)
    runner.idx += 1
    runner.idx > length(runner.img_paths) && return nothing
    img = load(joinpath("./imgs", runner.img_paths[runner.idx])) .|> RGB

    @info "loaded" runner.idx runner.img_paths[runner.idx] size(img)
    return img, split(runner.img_paths[runner.idx], ".")[1]
end

function load_prev(runner::CropperRunner)
    runner.idx -= 2
    runner.idx < 1 && return nothing
    return load_next(runner)
end

function crop(img, x, y, width)
    y = size(img, 1) - y
                
    # crop image
    r(x) = round(Int, x)
    x0, y0 = r(x-width), r(y-width)
    x1, y1 = x0+2width-1, y0+2width-1
    @debug "clicked" size(img) x y x0 y0 x1 y1

    if x0<1 || y0<1 || x1>size(img, 2) || y1>size(img, 1)
        @warn "out of bounds"
        return nothing
    end

    return img[y0:y1, x0:x1]
end


function crop_images(tag; width=160)
    runner = CropperRunner("./imgs")
    img, name = load_next(runner)


    obs_img = GLMakie.Observable(rotr90(img))
    scene = GLMakie.Scene(camera=GLMakie.campixel!, resolution=reverse(size(img)))
    GLMakie.image!(scene, obs_img)
    display(scene)
    clicked = 0

    on(events(scene).mousebutton, priority = 0) do event
        if event.button == Mouse.left &&  event.action == Mouse.press
                x, y = mouseposition(scene)
                cropped = crop(img, x, y, width)
        
                isnothing(cropped) || begin
                    save("./imgs/$tag/$(name)_$clicked.png", cropped)
                    @info "saved" "$tag/$(name)_$clicked.png" size(cropped)
                    clicked += 1
                end
        end
    end

    on(events(scene).keyboardbutton) do event
        if event.action in (Keyboard.press, )
            if event.key == Keyboard.right
                img, name = load_next(runner)
                clicked = 0
                isnothing(img) && return Consume(false)
                obs_img[] = rotr90(img)
            elseif event.key == Keyboard.left
                img, name = load_prev(runner)
                clicked = 0
                isnothing(img) && return Consume(false)
                obs_img[] = rotr90(img)
            end
        end
       return Consume(false)
    end

    nothing
end

# ------------------------------------ run ----------------------------------- #
# save_camera_frames("./imgs", 20)

tag = "null"
crop_images(tag; width=40)    
