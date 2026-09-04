cask "skilldrop" do
  version "1.2.2"
  sha256 "b3a8b2c278a6848290fce7d65e1aca4c48064e8b1ddd70dbe8962c44b057ab66"

  url "https://github.com/Blackphi6/SkillDrop/releases/download/v#{version}/SkillDrop-macos-arm64.zip"
  name "SkillDrop"
  desc "Install GitHub Agent Skills into Cursor, Claude Code, and Codex"
  homepage "https://github.com/Blackphi6/SkillDrop"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "SkillDrop.app"

  # 未公証バイナリでも、brew 経由ならここだけで隔離を外せる
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/SkillDrop.app"]
  end

  zap trash: [
    "~/Library/Preferences/local.skilldrop.app.plist",
  ]
end
