  test "tag 0 repo contains an empty output file" do
    kata = make_kata(language)
    avatar = Avatar.new(kata, 'wolf') 
    visible_files = avatar.visible_files
    assert visible_files.keys.include?('output'),
          "visible_files.keys.include?('output')"
    assert_equal "", visible_files['output']
  end
